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

    -- Krok 0: Pobranie ID usera
    SELECT id_autora INTO v_id_asystenta
    FROM Mapowanie_Uzytkownik_Autor
    WHERE nazwa_uzytkownika_db = USER()
    LIMIT 1;

    -- Krok 0b: Pobranie ID statusu 
    SELECT id_decyzji INTO v_id_decyzji_startowej
    FROM Decyzja_Slownik WHERE nazwa_decyzji = 'W trakcie' LIMIT 1;

    IF v_id_decyzji_startowej IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Błąd konfiguracji: Brak statusu "W trakcie" w słowniku.';
    END IF;

    START TRANSACTION;

        -- Krok 2: Pobierz dane i ZABLOKUJ wiersz
        SELECT tytul, doi_proponowane, rok_proponowany, id_czasopisma_docelowego
        INTO v_tytul, v_doi, v_rok, v_id_czasopisma
        FROM Zgloszenie_Wstepne
        WHERE id_zgloszenia = p_id_zgloszenia 
        AND status_wstepny = 'W filtracji'
        FOR UPDATE;

        IF v_tytul IS NULL THEN
            ROLLBACK;
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Błąd: Zgłoszenie nie istnieje, ma zły status lub nie masz do niego dostępu.';
        END IF;

        -- Krok 5: Wstaw do głównej tabeli Artykul
        INSERT INTO Artykul (tytul, doi, rok_publikacji, data_ostatniej_aktualizacji, id_czasopisma)
        VALUES (v_tytul, v_doi, v_rok, CURDATE(), v_id_czasopisma);
        
        SET v_id_artykulu = LAST_INSERT_ID();

        -- Krok 6: Kopiuj autorów
        INSERT INTO Artykul_Autor (id_artykulu, id_autora, kolejnosc_autora)
        SELECT v_id_artykulu, id_autora, kolejnosc_autora
        FROM Zgloszenie_Wstepne_Autor
        WHERE id_zgloszenia = p_id_zgloszenia;

        -- Krok 7: Kopiuj dyscypliny
        INSERT INTO Artykul_Dyscyplina (id_artykulu, id_dyscypliny)
        SELECT v_id_artykulu, id_dyscypliny
        FROM Zgloszenie_Wstepne_Dyscyplina
        WHERE id_zgloszenia = p_id_zgloszenia;

        -- Krok 8: Stwórz pierwszą rundę
        INSERT INTO RundaRecenzyjna (id_artykulu, numer_rundy, data_rozpoczecia, id_decyzji)
        VALUES (v_id_artykulu, 1, CURDATE(), v_id_decyzji_startowej);

        -- Krok 9: Zmień status zgłoszenia (żeby nie przetworzyć go drugi raz)
        UPDATE Zgloszenie_Wstepne
        SET status_wstepny = 'Zaakceptowane'
        WHERE id_zgloszenia = p_id_zgloszenia;

    COMMIT;
    
    SELECT 'Zgłoszenie zostało zaakceptowane i w pełni przeniesione do systemu.' AS 'Status';
END$$

DELIMITER ;