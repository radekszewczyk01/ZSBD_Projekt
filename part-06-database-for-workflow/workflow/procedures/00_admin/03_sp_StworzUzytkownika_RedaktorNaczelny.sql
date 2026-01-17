/*--- WYKONAJ JAKO ADMINISTRATOR ---*/
USE rims_v2;

-- Usuwamy starą wersję procedury, jeśli istnieje
DROP PROCEDURE IF EXISTS sp_StworzUzytkownika_RedaktorNaczelny;

DELIMITER $$

CREATE PROCEDURE sp_StworzUzytkownika_RedaktorNaczelny(
    IN p_nazwa_uzytkownika VARCHAR(100), -- np. 'red_naczelny_nowak'
    IN p_haslo VARCHAR(100),             -- np. 'SuperTajneHaslo123!'
    IN p_id_autora INT,                  -- ID autora, który istnieje w tabeli Autor
    IN p_id_czasopisma INT               -- ID czasopisma, którym będzie zarządzał
)
BEGIN
    -- Deklaracja zmiennych
    DECLARE v_pelna_nazwa_uzytkownika VARCHAR(193);
    
    -- Handler błędów (wycofa transakcję w razie problemu)
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL; 
    END;

    -- Ustawienie pełnej nazwy użytkownika (np. 'red_naczelny_nowak@localhost')
    SET v_pelna_nazwa_uzytkownika = CONCAT(QUOTE(p_nazwa_uzytkownika), '@\'localhost\'');

    -- Rozpocznij transakcję
    START TRANSACTION;

    -- KROK 1: Stwórz użytkownika bazy danych
    SET @sql_create_user = CONCAT('CREATE USER ', v_pelna_nazwa_uzytkownika, 
                                  ' IDENTIFIED BY ', QUOTE(p_haslo));
    PREPARE stmt1 FROM @sql_create_user;
    EXECUTE stmt1;
    DEALLOCATE PREPARE stmt1;

    -- KROK 2: Nadaj nowemu użytkownikowi wszystkie potrzebne role
    -- Redaktor Naczelny musi być Autorem (aby móc publikować),
    -- Asystentem (aby zarządzać procesem) i Naczelnym (aby mieć widoki).
    
    SET @sql_grant_autor = CONCAT('GRANT \'RolaAutora\' TO ', v_pelna_nazwa_uzytkownika);
    PREPARE stmt_a FROM @sql_grant_autor;
    EXECUTE stmt_a;
    DEALLOCATE PREPARE stmt_a;
    
    SET @sql_grant_asystent = CONCAT('GRANT \'RolaAsystenta\' TO ', v_pelna_nazwa_uzytkownika);
    PREPARE stmt_b FROM @sql_grant_asystent;
    EXECUTE stmt_b;
    DEALLOCATE PREPARE stmt_b;

    SET @sql_grant_naczelny = CONCAT('GRANT \'RolaRedaktoraNaczelnego\' TO ', v_pelna_nazwa_uzytkownika); 
    PREPARE stmt_c FROM @sql_grant_naczelny;
    EXECUTE stmt_c;
    DEALLOCATE PREPARE stmt_c;


    -- KROK 3: Wstaw mapowanie do tabeli Mapowanie_Uzytkownik_Autor
    -- (Łączy użytkownika 'red_naczelny_nowak@localhost' z rekordem Autora np. 15)
    INSERT INTO Mapowanie_Uzytkownik_Autor (nazwa_uzytkownika_db, id_autora) 
    VALUES (CONCAT(p_nazwa_uzytkownika, '@localhost'), p_id_autora);
    
    -- KROK 4: Mianuj redaktorem naczelnym w tabeli Czasopismo
    -- (Ustawia Czasopismo.id_redaktora_naczelnego = 15)
    UPDATE Czasopismo
    SET 
        id_redaktora_naczelnego = p_id_autora
    WHERE 
        id_czasopisma = p_id_czasopisma;
        
    -- Sprawdzenie, czy czasopismo na pewno zostało zaktualizowane
    IF ROW_COUNT() = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Błąd: Nie znaleziono czasopisma o podanym ID. Transakcja wycofana.';
    END IF;

    -- KROK 5: Zakończ transakcję
    COMMIT;

    -- KROK 6: Odśwież uprawnienia
    FLUSH PRIVILEGES;

    -- Pokaż komunikat o sukcesie
    SELECT CONCAT('Sukces: Stworzono użytkownika ', p_nazwa_uzytkownika, 
                  ' i mianowano redaktorem naczelnym czasopisma ID = ', p_id_czasopisma) AS 'Status';

END$$

-- Przywrócenie domyślnego terminatora
DELIMITER ;