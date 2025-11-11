/*--- WYKONAJ JAKO ADMINISTRATOR ---*/
USE rims_v2;
DROP PROCEDURE IF EXISTS sp_Redaktor_ZaprosRecenzenta;

DELIMITER $$
CREATE PROCEDURE sp_Redaktor_ZaprosRecenzenta(
    IN p_id_rundy INT,            -- Do której rundy zapraszasz?
    IN p_id_autora_recenzenta INT -- Kogo zapraszasz?
)
BEGIN
    DECLARE v_id_redaktora_zalogowanego INT;
    DECLARE v_id_redaktora_prowadzacego INT;
    DECLARE v_id_artykulu INT;

    -- 1. Znajdź ID zalogowanego użytkownika
    SELECT id_autora INTO v_id_redaktora_zalogowanego
    FROM Mapowanie_Uzytkownik_Autor
    WHERE nazwa_uzytkownika_db = USER() LIMIT 1;

    -- 2. Sprawdź, kto jest redaktorem prowadzącym tej rundy
    SELECT id_redaktora_prowadzacego, id_artykulu
    INTO v_id_redaktora_prowadzacego, v_id_artykulu
    FROM RundaRecenzyjna
    WHERE id_rundy = p_id_rundy;

    -- 3. Sprawdzenie bezpieczeństwa: Czy to TY prowadzisz tę rundę?
    IF v_id_redaktora_zalogowanego IS NULL OR v_id_redaktora_zalogowanego <> v_id_redaktora_prowadzacego THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Błąd: Nie jesteś redaktorem prowadzącym tej rundy.';
    END IF;

    -- 4. Sprawdzenie logiki: Czy recenzent jest autorem artykułu?
    IF EXISTS (SELECT 1 FROM Artykul_Autor WHERE id_artykulu = v_id_artykulu AND id_autora = p_id_autora_recenzenta) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Błąd: Nie można zaprosić autora artykułu do jego recenzowania.';
    END IF;

    -- 5. Zaproszenie: Wstaw pusty rekord recenzji
    -- (Później recenzent będzie go aktualizował)
    INSERT INTO Recenzja 
        (id_rundy, id_autora_recenzenta, id_rekomendacji, data_otrzymania)
    VALUES
        (p_id_rundy, p_id_autora_recenzenta, NULL, NULL)
    -- Zabezpieczenie na wypadek próby zaproszenia tej samej osoby dwa razy
    ON DUPLICATE KEY UPDATE id_rundy = p_id_rundy; 

    SELECT 'Sukces: Zaproszono recenzenta.' AS 'Status';

END$$
DELIMITER ;

-- Nadaj uprawnienia Redaktorom (RolaAsystenta)
GRANT EXECUTE ON PROCEDURE rims_v2.sp_Redaktor_ZaprosRecenzenta TO 'RolaAsystenta';