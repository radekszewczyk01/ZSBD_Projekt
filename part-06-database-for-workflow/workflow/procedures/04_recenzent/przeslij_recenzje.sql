DELIMITER $$
CREATE PROCEDURE sp_Recenzent_PrzeslijRecenzje(
    IN p_id_recenzji INT,
    IN p_nazwa_rekomendacji VARCHAR(100),
    IN p_tresc_recenzji TEXT
)
BEGIN
    DECLARE v_id_recenzenta INT;
    DECLARE v_id_rekomendacji INT;
    DECLARE v_przypisany_recenzent INT;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    SELECT id_autora INTO v_id_recenzenta
    FROM Mapowanie_Uzytkownik_Autor
    WHERE nazwa_uzytkownika_db = USER() LIMIT 1;

    SELECT id_rekomendacji INTO v_id_rekomendacji
    FROM Rekomendacja_Slownik
    WHERE nazwa_rekomendacji = p_nazwa_rekomendacji;
    
    IF v_id_rekomendacji IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Błąd: Podana nazwa rekomendacji jest nieprawidłowa.';
    END IF;

    START TRANSACTION;

        SELECT id_autora_recenzenta INTO v_przypisany_recenzent
        FROM Recenzja
        WHERE id_recenzji = p_id_recenzji
        FOR UPDATE;

        IF v_przypisany_recenzent IS NULL OR v_id_recenzenta <> v_przypisany_recenzent THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Błąd: Nie jesteś przypisany do wykonania tej recenzji.';
        END IF;
        
        UPDATE Recenzja
        SET
            id_rekomendacji = v_id_rekomendacji,
            tresc_recenzji = p_tresc_recenzji,
            data_otrzymania = CURDATE()
        WHERE
            id_recenzji = p_id_recenzji;

    COMMIT;

    SELECT 'Sukces: Recenzja została przesłana.' AS 'Status';

END$$
DELIMITER ;