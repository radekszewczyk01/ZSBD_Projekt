/*--- WYKONAJ JAKO ADMINISTRATOR ---*/
USE rims_v2;
DROP FUNCTION IF EXISTS fn_SprawdzZgodnoscDyscyplin;

DELIMITER $$
CREATE FUNCTION fn_SprawdzZgodnoscDyscyplin(
    p_id_zgloszenia INT
)
RETURNS BOOLEAN
READS SQL DATA -- Oznaczamy, że tylko czyta dane
BEGIN
    DECLARE v_zgodnosc_znaleziona BOOLEAN DEFAULT FALSE;

    -- Sprawdź, czy istnieje jakikolwiek rekord, gdzie dyscyplina autora
    -- pasuje do dyscypliny zgłoszenia dla tego samego autora
    SELECT EXISTS (
        SELECT 1
        FROM Zgloszenie_Wstepne_Autor zwa -- Autorzy zgłoszenia
        
        -- POPRAWKA JEST TUTAJ: (było Autor_Dyscypliny)
        JOIN Autor_Dyscyplina ad ON zwa.id_autora = ad.id_autora -- Osobiste dyscypliny tych autorów
        
        JOIN Zgloszenie_Wstepne_Dyscyplina zwd ON ad.id_dyscypliny = zwd.id_dyscypliny -- Dyscypliny podane w zgłoszeniu
        WHERE 
            zwa.id_zgloszenia = p_id_zgloszenia
            AND zwd.id_zgloszenia = p_id_zgloszenia
    ) INTO v_zgodnosc_znaleziona;
    
    RETURN v_zgodnosc_znaleziona;
END$$
DELIMITER ;