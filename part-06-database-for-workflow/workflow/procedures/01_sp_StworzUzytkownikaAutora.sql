-- run tables and roles scripts first
-- run this in terminal (doesn't work in MySQL Workbench)

-- @blok1
USE rims_v2;

-- @blok2
-- Zmiana terminatora, aby procedura mogła być zdefiniowana jako całość
DELIMITER $$

CREATE PROCEDURE sp_StworzUzytkownikaAutora(
    IN p_nazwa_uzytkownika VARCHAR(100), -- np. 'prof_kowalski'
    IN p_haslo VARCHAR(100),            -- np. 'SilneHasloNowaka123!'
    IN p_id_autora INT                  -- np. 123
)
BEGIN
    -- Deklaracja zmiennych lokalnych
    DECLARE v_pelna_nazwa_uzytkownika VARCHAR(193);
    
    -- Deklaracja handlera błędów (na wypadek, gdyby użytkownik już istniał)
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        -- Wycofaj transakcję, jeśli coś poszło nie tak
        ROLLBACK;
        -- Zwróć błąd
        RESIGNAL; 
    END;

    -- Ustawienie pełnej nazwy użytkownika (np. 'prof_kowalski@localhost')
    -- Używamy funkcji QUOTE(), aby zabezpieczyć się przed SQL injection
    SET v_pelna_nazwa_uzytkownika = CONCAT(QUOTE(p_nazwa_uzytkownika), '@\'localhost\'');

    -- Rozpocznij transakcję
    START TRANSACTION;

    -- KROK 1: Stwórz użytkownika bazy danych
    -- Używamy dynamicznego SQL, ponieważ CREATE USER nie może być wprost w procedurze
    SET @sql_create_user = CONCAT('CREATE USER ', v_pelna_nazwa_uzytkownika, 
                                  ' IDENTIFIED BY ', QUOTE(p_haslo));
    PREPARE stmt1 FROM @sql_create_user;
    EXECUTE stmt1;
    DEALLOCATE PREPARE stmt1;

    -- KROK 2: Nadaj nowemu użytkownikowi 'RolaAutora'
    SET @sql_grant_role = CONCAT('GRANT \'RolaAutora\' TO ', v_pelna_nazwa_uzytkownika);
    PREPARE stmt2 FROM @sql_grant_role;
    EXECUTE stmt2;
    DEALLOCATE PREPARE stmt2;

    -- KROK 3: Wstaw mapowanie do tabeli Mapowanie_Uzytkownik_Autor
    -- Tutaj już nie potrzebujemy dynamicznego SQL
    INSERT INTO Mapowanie_Uzytkownik_Autor (nazwa_uzytkownika_db, id_autora) 
    VALUES (CONCAT(p_nazwa_uzytkownika, '@localhost'), p_id_autora);
    
    -- KROK 4: Zakończ transakcję
    COMMIT;

    -- KROK 5: Odśwież uprawnienia (zalecane po CREATE USER)
    FLUSH PRIVILEGES;

    -- Pokaż komunikat o sukcesie
    SELECT CONCAT('Sukces: Stworzono użytkownika ', v_pelna_nazwa_uzytkownika, 
                  ' i powiązano z id_autora = ', p_id_autora) AS 'Status';

END$$

-- Przywrócenie domyślnego terminatora
DELIMITER ;