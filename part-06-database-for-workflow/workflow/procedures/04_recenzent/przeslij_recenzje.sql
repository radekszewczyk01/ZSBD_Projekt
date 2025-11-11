/*--- WYKONAJ JAKO ADMINISTRATOR ---*/
USE rims_v2;
DROP PROCEDURE IF EXISTS sp_Recenzent_PrzeslijRecenzje;

DELIMITER $$
CREATE PROCEDURE sp_Recenzent_PrzeslijRecenzje(
    IN p_id_recenzji INT,                       -- Którą recenzję wypełniasz?
    IN p_nazwa_rekomendacji VARCHAR(100),       -- Jaka jest Twoja decyzja? (np. 'Drobne poprawki')
    IN p_tresc_recenzji TEXT                    -- Treść Twojej oceny
)
BEGIN
    DECLARE v_id_recenzenta INT;
    DECLARE v_id_rekomendacji INT;
    DECLARE v_przypisany_recenzent INT;

    -- Krok 1: Znajdź ID zalogowanego użytkownika
    SELECT id_autora INTO v_id_recenzenta
    FROM Mapowanie_Uzytkownik_Autor
    WHERE nazwa_uzytkownika_db = USER() LIMIT 1;

    -- Krok 2: Znajdź ID rekomendacji na podstawie tekstu
    SELECT id_rekomendacji INTO v_id_rekomendacji
    FROM Rekomendacja_Slownik
    WHERE nazwa_rekomendacji = p_nazwa_rekomendacji;
    
    IF v_id_rekomendacji IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Błąd: Podana nazwa rekomendacji jest nieprawidłowa.';
    END IF;

    -- Krok 3: Weryfikacja bezpieczeństwa
    -- Sprawdź, kto jest przypisany do tej recenzji
    SELECT id_autora_recenzenta INTO v_przypisany_recenzent
    FROM Recenzja
    WHERE id_recenzji = p_id_recenzji
    FOR UPDATE; -- Zablokuj wiersz na czas aktualizacji

    -- Sprawdź, czy to NA PEWNO Ty
    IF v_przypisany_recenzent IS NULL OR v_id_recenzenta <> v_przypisany_recenzent THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Błąd: Nie jesteś przypisany do wykonania tej recenzji.';
    END IF;
    
    -- Krok 4: Aktualizuj recenzję
    UPDATE Recenzja
    SET
        id_rekomendacji = v_id_rekomendacji,
        tresc_recenzji = p_tresc_recenzji,
        data_otrzymania = CURDATE()
    WHERE
        id_recenzji = p_id_recenzji;

    SELECT 'Sukces: Recenzja została przesłana.' AS 'Status';

END$$
DELIMITER ;

-- Nadaj uprawnienia RoliAutora