-- Wykonaj jako administrator (np. nowy_admin)
USE rims_v2;
DROP PROCEDURE IF EXISTS sp_Autor_ZglosArtykul;

DELIMITER $$

CREATE PROCEDURE sp_Autor_ZglosArtykul(
    IN p_tytul VARCHAR(500),
    IN p_doi VARCHAR(100),
    IN p_rok INT,
    IN p_id_czasopisma_docelowego INT -- Autor wybiera czasopismo, do którego zgłasza
)
BEGIN
    DECLARE v_id_autora_zglaszajacego INT;

    -- Znajdź ID zalogowanego autora
    SELECT id_autora INTO v_id_autora_zglaszajacego
    FROM Mapowanie_Uzytkownik_Autor
    WHERE nazwa_uzytkownika_db = USER()
    LIMIT 1;
    
    IF v_id_autora_zglaszajacego IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Błąd: Zalogowany użytkownik nie jest zmapowany do autora.';
    END IF;

    -- Wstawia zgłoszenie do poczekalni
    INSERT INTO Zgloszenie_Wstepne 
        (tytul, doi_proponowane, rok_proponowany, id_autora_zglaszajacego, id_czasopisma_docelowego, data_zgloszenia, status_wstepny)
    VALUES
        (p_tytul, p_doi, p_rok, v_id_autora_zglaszajacego, p_id_czasopisma_docelowego, CURDATE(), 'Oczekuje');
        
    SELECT 'Zgłoszenie zostało wysłane i oczekuje na weryfikację przez asystenta.' AS 'Status';
END$$

DELIMITER ;

-- Nadaj autorowi prawo do zgłaszania
GRANT EXECUTE ON PROCEDURE rims_v2.sp_Autor_ZglosArtykul TO 'RolaAutora';