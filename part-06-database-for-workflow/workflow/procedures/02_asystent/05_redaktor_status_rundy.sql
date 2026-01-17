/*--- WYKONAJ JAKO ADMINISTRATOR ---*/
USE rims_v2;
DROP PROCEDURE IF EXISTS sp_Redaktor_PodejmijDecyzje;

DELIMITER $$
CREATE PROCEDURE sp_Redaktor_PodejmijDecyzje(
    IN p_id_rundy INT,                    -- Którą rundę chcesz zaktualizować?
    IN p_nazwa_decyzji VARCHAR(100)       -- Jaki status chcesz ustawić? (np. 'Odrzucony')
)
BEGIN
    DECLARE v_id_redaktora_zalogowanego INT;
    DECLARE v_id_redaktora_prowadzacego INT;
    DECLARE v_id_decyzji_nowej INT;
    DECLARE v_data_zakonczenia DATE DEFAULT NULL;

    -- Krok 1: Znajdź ID zalogowanego użytkownika
    SELECT id_autora INTO v_id_redaktora_zalogowanego
    FROM Mapowanie_Uzytkownik_Autor
    WHERE nazwa_uzytkownika_db = USER() LIMIT 1;

    -- Krok 2: Sprawdź, kto jest redaktorem prowadzącym tej rundy
    SELECT id_redaktora_prowadzacego INTO v_id_redaktora_prowadzacego
    FROM RundaRecenzyjna
    WHERE id_rundy = p_id_rundy
    FOR UPDATE; -- Zablokuj wiersz na czas aktualizacji

    -- Krok 3: Sprawdzenie bezpieczeństwa (Krytyczne!)
    -- Czy to na pewno TY prowadzisz tę rundę?
    IF v_id_redaktora_zalogowanego IS NULL OR v_id_redaktora_zalogowanego <> v_id_redaktora_prowadzacego THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Błąd: Nie jesteś redaktorem prowadzącym tej rundy.';
    END IF;

    -- Krok 4: Znajdź ID nowej decyzji (statusu)
    SELECT id_decyzji INTO v_id_decyzji_nowej
    FROM Decyzja_Slownik
    WHERE nazwa_decyzji = p_nazwa_decyzji;
    
    IF v_id_decyzji_nowej IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Błąd: Podana nazwa decyzji jest nieprawidłowa.';
    END IF;

    -- Krok 5: Sprawdź, czy to decyzja kończąca (i ustaw datę zakończenia)
    IF p_nazwa_decyzji IN ('Zaakceptowany', 'Odrzucony') THEN
        SET v_data_zakonczenia = CURDATE();
    END IF;

    -- Krok 6: Wykonaj aktualizację
    UPDATE RundaRecenzyjna
    SET
        id_decyzji = v_id_decyzji_nowej,
        data_zakonczenia = v_data_zakonczenia
    WHERE
        id_rundy = p_id_rundy;
        
    SELECT CONCAT('Sukces: Zmieniono status rundy ID ', p_id_rundy, ' na "', p_nazwa_decyzji, '".') AS 'Status';

END$$
DELIMITER ;