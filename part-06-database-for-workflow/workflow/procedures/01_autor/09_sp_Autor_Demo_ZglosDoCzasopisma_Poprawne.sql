/*--- WYKONAJ JAKO ADMINISTRATOR (np. nowy_admin) ---*/
USE rims_v2;

DROP PROCEDURE IF EXISTS sp_Autor_Demo_ZglosDoCzasopisma_Poprawne;
DELIMITER $$

CREATE DEFINER=CURRENT_USER PROCEDURE sp_Autor_Demo_ZglosDoCzasopisma_Poprawne(
    IN p_nazwa_czasopisma VARCHAR(255) 
)
SQL SECURITY DEFINER
BEGIN
    -- Deklaracja zmiennych
    DECLARE v_id_autora_zglaszajacego INT;
    DECLARE v_id_zgloszenia INT;
    DECLARE v_id_czasopisma INT;
    DECLARE v_wspolautor_id_1 INT;
    DECLARE v_wspolautor_id_2 INT;
    DECLARE v_dyscyplina_id_1 INT;
    DECLARE v_dyscyplina_id_2 INT;
    DECLARE v_tytul VARCHAR(500);
    DECLARE v_doi VARCHAR(100);
    DECLARE v_rok INT DEFAULT YEAR(CURDATE());
    
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL; -- Zwróć błąd do klienta
    END;

    -- Krok 1: Znajdź ID zalogowanego autora
    SELECT id_autora INTO v_id_autora_zglaszajacego
    FROM Mapowanie_Uzytkownik_Autor
    WHERE nazwa_uzytkownika_db = USER()
    LIMIT 1;

    IF v_id_autora_zglaszajacego IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Błąd: Zalogowany użytkownik nie jest zmapowany do autora.';
    END IF;

    -- Krok 2: Znajdź ID czasopisma
    SELECT id_czasopisma INTO v_id_czasopisma 
    FROM Czasopismo 
    WHERE tytul = p_nazwa_czasopisma 
    LIMIT 1;

    IF v_id_czasopisma IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Błąd: Czasopismo o podanej nazwie nie zostało znalezione.';
    END IF;

    -- Krok 3: Losowe dane (Tytuł, DOI, Autorzy)
    SET v_tytul = CONCAT('Losowy artykuł testowy (', UUID_SHORT(), ')');
    SET v_doi = CONCAT('10.9999/demo.', UUID_SHORT());
    
    SELECT id_autora INTO v_wspolautor_id_1 FROM Autor 
    WHERE id_autora <> v_id_autora_zglaszajacego ORDER BY RAND() LIMIT 1;
    
    SELECT id_autora INTO v_wspolautor_id_2 FROM Autor 
    WHERE id_autora <> v_id_autora_zglaszajacego AND id_autora <> v_wspolautor_id_1 ORDER BY RAND() LIMIT 1;


    -- =================================================================
    -- START POPRAWIONEJ LOGIKI (Wybór dyscyplin)
    -- =================================================================
    
    -- Spróbuj znaleźć pierwszą dyscyplinę z puli specjalizacji autorów
    SELECT id_dyscypliny INTO v_dyscyplina_id_1 
    FROM Autor_Dyscyplina
    WHERE id_autora IN (v_id_autora_zglaszajacego, v_wspolautor_id_1, v_wspolautor_id_2)
    ORDER BY RAND() 
    LIMIT 1;

    -- Spróbuj znaleźć drugą, INNĄ dyscyplinę z tej samej puli
    SELECT id_dyscypliny INTO v_dyscyplina_id_2 
    FROM Autor_Dyscyplina
    WHERE id_autora IN (v_id_autora_zglaszajacego, v_wspolautor_id_1, v_wspolautor_id_2)
      AND (v_dyscyplina_id_1 IS NULL OR id_dyscypliny <> v_dyscyplina_id_1) -- Upewnij się, że jest inna
    ORDER BY RAND() 
    LIMIT 1;

    -- --- Mechanizm awaryjny (FALLBACK) ---
    -- Jeśli autorzy nie mieli żadnych dyscyplin (v_dyscyplina_id_1 jest NULL)
    -- wylosuj jakąkolwiek.
    IF v_dyscyplina_id_1 IS NULL THEN
        SELECT id_dyscypliny INTO v_dyscyplina_id_1 FROM Dyscypliny ORDER BY RAND() LIMIT 1;
    END IF;
    
    -- Jeśli pula autorów miała tylko 1 dyscyplinę (v_dyscyplina_id_2 jest NULL)
    -- wylosuj jakąkolwiek inną niż pierwsza.
    IF v_dyscyplina_id_2 IS NULL THEN
        SELECT id_dyscypliny INTO v_dyscyplina_id_2 FROM Dyscypliny 
        WHERE id_dyscypliny <> v_dyscyplina_id_1 
        ORDER BY RAND() LIMIT 1;
    END IF;

    -- =================================================================
    -- KONIEC POPRAWIONEJ LOGIKI
    -- =================================================================

    -- Krok 4: Rozpocznij transakcję
    START TRANSACTION;

    -- Krok 5: Wstaw do poczekalni (Zgloszenie_Wstepne)
    INSERT INTO Zgloszenie_Wstepne 
        (tytul, doi_proponowane, rok_proponowany, id_autora_zglaszajacego, id_czasopisma_docelowego, data_zgloszenia, status_wstepny)
    VALUES 
        (v_tytul, v_doi, v_rok, v_id_autora_zglaszajacego, v_id_czasopisma, CURDATE(), 'Oczekuje');
        
    SET v_id_zgloszenia = LAST_INSERT_ID();

    -- Krok 6: Wstaw autorów do poczekalni (Zgloszenie_Wstepne_Autor)
    INSERT INTO Zgloszenie_Wstepne_Autor (id_zgloszenia, id_autora, kolejnosc_autora)
    VALUES 
        (v_id_zgloszenia, v_id_autora_zglaszajacego, 1),
        (v_id_zgloszenia, v_wspolautor_id_1, 2),
        (v_id_zgloszenia, v_wspolautor_id_2, 3);

    -- Krok 7: Wstaw dyscypliny do poczekalni (Zgloszenie_Wstepne_Dyscyplina)
    INSERT INTO Zgloszenie_Wstepne_Dyscyplina (id_zgloszenia, id_dyscypliny)
    VALUES
        (v_id_zgloszenia, v_dyscyplina_id_1),
        (v_id_zgloszenia, v_dyscyplina_id_2);

    -- Krok 8: Zatwierdź transakcję
    COMMIT;
    
    SELECT CONCAT('Sukces: Zgłoszono "poprawny" artykuł (ID Zgłoszenia: ', v_id_zgloszenia, ') do czasopisma "', p_nazwa_czasopisma, '".') AS 'Status';

END$$

DELIMITER ;