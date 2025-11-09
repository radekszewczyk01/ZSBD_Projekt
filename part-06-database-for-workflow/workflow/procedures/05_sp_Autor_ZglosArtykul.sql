/*--- WYKONAJ JAKO ADMINISTRATOR (np. nowy_admin) ---*/
USE rims_v2;
DROP PROCEDURE IF EXISTS sp_Autor_ZglosArtykul;

DELIMITER $$

CREATE PROCEDURE sp_Autor_ZglosArtykul(
    IN p_tytul VARCHAR(500),
    IN p_doi VARCHAR(100),
    IN p_rok INT,
    IN p_id_czasopisma_docelowego INT,
    IN p_wspolautorzy_csv TEXT, -- Lista ID oddzielonych przecinkami, np. "12,45,101"
    IN p_dyscypliny_csv TEXT     -- Lista ID oddzielonych przecinkami, np. "1,5"
)
BEGIN
    DECLARE v_id_autora_zglaszajacego INT;
    DECLARE v_id_zgloszenia INT;

    -- Zmienne do pętli (dla parsowania CSV)
    DECLARE v_id_single INT;
    DECLARE v_idx INT;
    DECLARE v_remaining_list TEXT;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    -- Krok 1: Znajdź zalogowanego autora
    SELECT id_autora INTO v_id_autora_zglaszajacego
    FROM Mapowanie_Uzytkownik_Autor
    WHERE nazwa_uzytkownika_db = USER()
    LIMIT 1;
    
    IF v_id_autora_zglaszajacego IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Błąd: Zalogowany użytkownik nie jest zmapowany do autora.';
    END IF;

    -- Krok 2: Rozpocznij transakcję
    START TRANSACTION;

    -- Krok 3: Wstaw rekord do głównej poczekalni
    INSERT INTO Zgloszenie_Wstepne 
        (tytul, doi_proponowane, rok_proponowany, id_autora_zglaszajacego, id_czasopisma_docelowego, data_zgloszenia, status_wstepny)
    VALUES
        (p_tytul, p_doi, p_rok, v_id_autora_zglaszajacego, p_id_czasopisma_docelowego, CURDATE(), 'Oczekuje');
        
    SET v_id_zgloszenia = LAST_INSERT_ID();

    -- Krok 4: Wstaw autora zgłaszającego jako pierwszego do poczekalni autorów
    INSERT INTO Zgloszenie_Wstepne_Autor (id_zgloszenia, id_autora, kolejnosc_autora)
    VALUES (v_id_zgloszenia, v_id_autora_zglaszajacego, 1);
    
    -- Krok 5: Parsuj i wstaw współautorów (jeśli podano)
    SET v_remaining_list = p_wspolautorzy_csv;
    SET v_idx = 1;
    WHILE LENGTH(v_remaining_list) > 0 DO
        SET v_idx = v_idx + 1;
        SET v_id_single = CAST(SUBSTRING_INDEX(v_remaining_list, ',', 1) AS UNSIGNED);
        
        IF v_id_single <> v_id_autora_zglaszajacego AND v_id_single > 0 THEN
            INSERT IGNORE INTO Zgloszenie_Wstepne_Autor (id_zgloszenia, id_autora, kolejnosc_autora)
            VALUES (v_id_zgloszenia, v_id_single, v_idx);
        END IF;
        
        IF LOCATE(',', v_remaining_list) > 0 THEN
            SET v_remaining_list = SUBSTRING(v_remaining_list, LOCATE(',', v_remaining_list) + 1);
        ELSE
            SET v_remaining_list = '';
        END IF;
    END WHILE;

    -- Krok 6: Parsuj i wstaw dyscypliny
    SET v_remaining_list = p_dyscypliny_csv;
    WHILE LENGTH(v_remaining_list) > 0 DO
        SET v_id_single = CAST(SUBSTRING_INDEX(v_remaining_list, ',', 1) AS UNSIGNED);
        IF v_id_single > 0 THEN
            INSERT IGNORE INTO Zgloszenie_Wstepne_Dyscyplina (id_zgloszenia, id_dyscypliny)
            VALUES (v_id_zgloszenia, v_id_single);
        END IF;
        
        IF LOCATE(',', v_remaining_list) > 0 THEN
            SET v_remaining_list = SUBSTRING(v_remaining_list, LOCATE(',', v_remaining_list) + 1);
        ELSE
            SET v_remaining_list = '';
        END IF;
    END WHILE;

    -- Krok 7: Zatwierdź transakcję
    COMMIT;
    
    SELECT 'Zgłoszenie zostało wysłane i oczekuje na weryfikację przez asystenta.' AS 'Status';
END$$

-- Krok 3: Nadaj autorowi prawo do zgłaszania (bez zmian)
GRANT EXECUTE ON PROCEDURE rims_v2.sp_Autor_ZglosArtykul TO 'RolaAutora';