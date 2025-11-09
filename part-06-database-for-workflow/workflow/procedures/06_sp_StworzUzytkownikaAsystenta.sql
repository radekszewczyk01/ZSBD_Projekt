-- exec in terminal
/*--- WYKONAJ JAKO ADMINISTRATOR (np. nowy_admin) ---*/
USE rims_v2;

DROP PROCEDURE IF EXISTS sp_StworzUzytkownikaAsystenta;
DELIMITER $$

CREATE PROCEDURE sp_StworzUzytkownikaAsystenta(
    IN p_nazwa_uzytkownika VARCHAR(100), -- np. 'asystent_anna'
    IN p_haslo VARCHAR(100),            -- np. 'SilneHasloAnny456!'
    IN p_id_autora INT                  -- np. 45 (ID Anny w tabeli Autor)
)
BEGIN
    DECLARE v_pelna_nazwa_uzytkownika VARCHAR(193);
    
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL; 
    END;

    SET v_pelna_nazwa_uzytkownika = CONCAT(QUOTE(p_nazwa_uzytkownika), '@\'localhost\'');

    START TRANSACTION;

    -- KROK 1: Stwórz użytkownika
    SET @sql_create_user = CONCAT('CREATE USER ', v_pelna_nazwa_uzytkownika, 
                                  ' IDENTIFIED BY ', QUOTE(p_haslo));
    PREPARE stmt1 FROM @sql_create_user;
    EXECUTE stmt1;
    DEALLOCATE PREPARE stmt1;

    -- KROK 2: Nadaj nowemu użytkownikowi 'RolaAsystenta' (JEDYNA ZMIANA)
    SET @sql_grant_role = CONCAT('GRANT \'RolaAsystenta\' TO ', v_pelna_nazwa_uzytkownika);
    PREPARE stmt2 FROM @sql_grant_role;
    EXECUTE stmt2;
    DEALLOCATE PREPARE stmt2;

    -- KROK 3: Wstaw mapowanie (Asystent też jest autorem)
    INSERT INTO Mapowanie_Uzytkownik_Autor (nazwa_uzytkownika_db, id_autora) 
    VALUES (CONCAT(p_nazwa_uzytkownika, '@localhost'), p_id_autora);
    
    COMMIT;
    FLUSH PRIVILEGES;

    SELECT CONCAT('Sukces: Stworzono użytkownika-ASYSTENTA ', v_pelna_nazwa_uzytkownika, 
                  ' i powiązano z id_autora = ', p_id_autora) AS 'Status';
END$$

DELIMITER ;