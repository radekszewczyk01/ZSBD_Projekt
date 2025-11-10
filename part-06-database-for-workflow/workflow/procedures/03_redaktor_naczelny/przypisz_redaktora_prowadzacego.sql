/*--- WYKONAJ JAKO ADMINISTRATOR ---*/
USE rims_v2;

DROP PROCEDURE IF EXISTS sp_Naczelny_PrzypiszRedaktoraDoRundy;
DELIMITER $$

CREATE PROCEDURE sp_Naczelny_PrzypiszRedaktoraDoRundy(
    IN p_id_rundy INT,            -- KURIĄ RUNDĘ CHCESZ ZMIENIĆ?
    IN p_id_nowego_redaktora INT  -- KOGO CHCESZ PRZYPISAĆ?
)
BEGIN
    DECLARE v_id_naczelnego INT;
    DECLARE v_id_czasopisma_naczelnego INT;
    DECLARE v_id_czasopisma_artykulu INT;
    DECLARE v_asystent_nalezy_do_czasopisma BOOLEAN DEFAULT FALSE;

    -- Handler błędów na wypadek niepowodzenia
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    -- Krok 1: Weryfikacja, kim jesteś (Redaktor Naczelny)
    -- Znajdź ID zalogowanego użytkownika
    SELECT id_autora INTO v_id_naczelnego
    FROM Mapowanie_Uzytkownik_Autor
    WHERE nazwa_uzytkownika_db = USER() LIMIT 1;

    -- Znajdź ID czasopisma, którym zarządzasz
    SELECT id_czasopisma INTO v_id_czasopisma_naczelnego
    FROM Czasopismo
    WHERE id_redaktora_naczelnego = v_id_naczelnego LIMIT 1;

    IF v_id_czasopisma_naczelnego IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Błąd: Nie jesteś redaktorem naczelnym żadnego czasopisma.';
    END IF;


    -- Krok 2: SPRAWDZENIE 1 (Czy artykuł jest z Twojego czasopisma?)
    -- Znajdź, do jakiego czasopisma należy artykuł związany z tą rundą
    SELECT a.id_czasopisma INTO v_id_czasopisma_artykulu
    FROM Artykul a
    JOIN RundaRecenzyjna rr ON a.id_artykulu = rr.id_artykulu
    WHERE rr.id_rundy = p_id_rundy;

    IF v_id_czasopisma_artykulu <> v_id_czasopisma_naczelnego THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Błąd: Ta runda recenzyjna nie dotyczy artykułu z Twojego czasopisma.';
    END IF;


    -- Krok 3: SPRAWDZENIE 2 (Czy asystent jest z Twojego czasopisma?)
    -- Sprawdź, czy asystent, którego próbujesz przypisać, jest w tabeli Asystent_Czasopisma
    SELECT EXISTS (
        SELECT 1 
        FROM Asystent_Czasopisma
        WHERE id_asystenta = p_id_nowego_redaktora
          AND id_czasopisma = v_id_czasopisma_naczelnego
    ) INTO v_asystent_nalezy_do_czasopisma;
    
    IF v_asystent_nalezy_do_czasopisma = FALSE THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Błąd: Ten asystent (Redaktor Prowadzący) nie jest przypisany do Twojego czasopisma.';
    END IF;

    
    -- Krok 4: Wykonanie akcji
    -- Wszystkie warunki spełnione, można zaktualizować rundę
    START TRANSACTION;
    
    UPDATE RundaRecenzyjna
    SET 
        id_redaktora_prowadzacego = p_id_nowego_redaktora
    WHERE 
        id_rundy = p_id_rundy;
        
    COMMIT;
    
    SELECT CONCAT('Sukces: Przypisano redaktora (ID: ', p_id_nowego_redaktora, ') do rundy (ID: ', p_id_rundy, ').') AS 'Status';

END$$
DELIMITER ;