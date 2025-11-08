-- execute in terminal
-- Upewnij się, że jesteś we właściwej bazie
USE rims_v2;

-- Usuń procedurę, jeśli istnieje, aby uniknąć błędów
DROP PROCEDURE IF EXISTS sp_PobierzAutorowDlaDyscypliny;

DELIMITER $$

CREATE PROCEDURE sp_PobierzAutorowDlaDyscypliny(
    IN p_nazwa_dyscypliny VARCHAR(100) -- Parametr wejściowy
)
BEGIN
    -- Ta procedura po prostu wykonuje zapytanie SELECT do istniejącego widoku,
    -- filtrując wyniki na podstawie podanej nazwy dyscypliny.
    SELECT 
        imie_autora,
        nazwisko_autora,
        orcid
    FROM 
        Perspektywa_Autor_Dyscyplina
    WHERE 
        -- Porównujemy kolumnę z widoku z naszym parametrem wejściowym
        nazwa_dyscypliny = p_nazwa_dyscypliny;
END$$

DELIMITER ;