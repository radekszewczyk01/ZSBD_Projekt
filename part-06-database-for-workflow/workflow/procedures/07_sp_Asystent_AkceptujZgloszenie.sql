/*--- WYKONAJ JAKO ADMINISTRATOR (np. nowy_admin) ---*/
USE rims_v2;
DROP PROCEDURE IF EXISTS sp_Asystent_AkceptujZgloszenie;

DELIMITER $$

CREATE PROCEDURE sp_Asystent_AkceptujZgloszenie(
    IN p_id_zgloszenia INT
)
BEGIN
    DECLARE v_tytul VARCHAR(500);
    DECLARE v_doi VARCHAR(100);
    DECLARE v_rok INT;
    DECLARE v_id_czasopisma INT;
    DECLARE v_id_artykulu INT;
    DECLARE v_id_decyzji_startowej INT;
    DECLARE v_id_asystenta INT;
    
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    -- Krok 1: Znajdź ID zalogowanego asystenta
    SELECT id_autora INTO v_id_asystenta
    FROM Mapowanie_Uzytkownik_Autor
    WHERE nazwa_uzytkownika_db = USER()
    LIMIT 1;

    -- Krok 2: Pobierz dane ze zgłoszenia (i upewnij się, że jest przypisane do MNIE)
    SELECT tytul, doi_proponowane, rok_proponowany, id_czasopisma_docelowego
    INTO v_tytul, v_doi, v_rok, v_id_czasopisma
    FROM Zgloszenie_Wstepne
    WHERE id_zgloszenia = p_id_zgloszenia 
      AND status_wstepny = 'W filtracji'
      AND id_przypisanego_asystenta = v_id_asystenta
    FOR UPDATE;

    IF v_tytul IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Błąd: Nie znaleziono zgłoszenia, ma zły status, lub nie jest przypisane do Ciebie.';
    END IF;

    -- Krok 3: Pobierz ID statusu "W trakcie" dla nowej rundy
    SELECT id_decyzji INTO v_id_decyzji_startowej
    FROM Decyzja_Slownik WHERE nazwa_decyzji = 'W trakcie' LIMIT 1;

    -- Krok 4: Rozpocznij transakcję
    START TRANSACTION;

    -- Krok 5: Wstaw do głównej tabeli Artykul
    INSERT INTO Artykul (tytul, doi, rok_publikacji, data_ostatniej_aktualizacji, id_czasopisma)
    VALUES (v_tytul, v_doi, v_rok, CURDATE(), v_id_czasopisma);
    SET v_id_artykulu = LAST_INSERT_ID();

    -- Krok 6: SKOPIUJ autorów z poczekalni do tabeli Artykul_Autor
    INSERT INTO Artykul_Autor (id_artykulu, id_autora, kolejnosc_autora)
    SELECT v_id_artykulu, id_autora, kolejnosc_autora
    FROM Zgloszenie_Wstepne_Autor
    WHERE id_zgloszenia = p_id_zgloszenia;

    -- Krok 7: SKOPIUJ dyscypliny z poczekalni do tabeli Artykul_Dyscyplina
    INSERT INTO Artykul_Dyscyplina (id_artykulu, id_dyscypliny)
    SELECT v_id_artykulu, id_dyscypliny
    FROM Zgloszenie_Wstepne_Dyscyplina
    WHERE id_zgloszenia = p_id_zgloszenia;

    -- Krok 8: Stwórz pierwszą rundę recenzji
    INSERT INTO RundaRecenzyjna (id_artykulu, numer_rundy, data_rozpoczecia, id_decyzji)
    VALUES (v_id_artykulu, 1, CURDATE(), v_id_decyzji_startowej);

    -- Krok 9: Zmień status w poczekalni na "Zaakceptowane"
    UPDATE Zgloszenie_Wstepne
    SET status_wstepny = 'Zaakceptowane'
    WHERE id_zgloszenia = p_id_zgloszenia;

    -- Krok 10: Zatwierdź
    COMMIT;
    
    SELECT 'Zgłoszenie zostało zaakceptowane i w pełni przeniesione do systemu.' AS 'Status';
END$$

DELIMITER ;

-- Krok 5: Nadaj asystentowi prawo do akceptacji (bez zmian)
GRANT EXECUTE ON PROCEDURE rims_v2.sp_Asystent_AkceptujZgloszenie TO 'RolaAsystenta';