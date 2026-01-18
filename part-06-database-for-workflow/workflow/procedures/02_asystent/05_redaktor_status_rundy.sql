DELIMITER $$
CREATE PROCEDURE sp_Redaktor_PodejmijDecyzje(
    IN p_id_rundy INT,
    IN p_nazwa_decyzji VARCHAR(100)
)
BEGIN
    DECLARE v_id_redaktora_zalogowanego INT;
    DECLARE v_id_redaktora_prowadzacego INT;
    DECLARE v_id_decyzji_nowej INT;
    DECLARE v_data_zakonczenia DATE DEFAULT NULL;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    -- Krok 1: Pobierz ID zalogowanego
    SELECT id_autora INTO v_id_redaktora_zalogowanego
    FROM Mapowanie_Uzytkownik_Autor
    WHERE nazwa_uzytkownika_db = USER() LIMIT 1;

    START TRANSACTION;

        -- Blokada trzyma teraz aż do COMMIT
        SELECT id_redaktora_prowadzacego INTO v_id_redaktora_prowadzacego
        FROM RundaRecenzyjna
        WHERE id_rundy = p_id_rundy
        FOR UPDATE;

        -- Walidacja: Czy runda istnieje?
        IF v_id_redaktora_prowadzacego IS NULL THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Błąd: Taka runda nie istnieje.';
        END IF;

        -- Krok 3: Sprawdzenie uprawnień
        IF v_id_redaktora_zalogowanego IS NULL OR v_id_redaktora_zalogowanego <> v_id_redaktora_prowadzacego THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Błąd: Nie jesteś redaktorem prowadzącym tej rundy.';
        END IF;

        -- Krok 4: Tłumaczenie nazwy na ID (może być wewnątrz transakcji)
        SELECT id_decyzji INTO v_id_decyzji_nowej
        FROM Decyzja_Slownik
        WHERE nazwa_decyzji = p_nazwa_decyzji;
        
        IF v_id_decyzji_nowej IS NULL THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Błąd: Podana nazwa decyzji jest nieprawidłowa.';
        END IF;

        -- Krok 5: Logika daty zakończenia
        IF p_nazwa_decyzji IN ('Zaakceptowany', 'Odrzucony') THEN
            SET v_data_zakonczenia = CURDATE(); -- lub NOW() jeśli zmienisz typ kolumny
        END IF;

        -- Krok 6: Aktualizacja
        UPDATE RundaRecenzyjna
        SET
            id_decyzji = v_id_decyzji_nowej,
            data_zakonczenia = v_data_zakonczenia
        WHERE
            id_rundy = p_id_rundy;

    COMMIT;
        
    SELECT CONCAT('Sukces: Zmieniono status rundy ID ', p_id_rundy, ' na "', p_nazwa_decyzji, '".') AS 'Status';

END$$
DELIMITER ;