-- run in terminal
DELIMITER $$

CREATE PROCEDURE sp_PobierzMojeSpecjalizacje()
BEGIN
    DECLARE v_id_autora INT;

    -- Krok 1: Znajdź ID zalogowanego użytkownika
    -- Użyj `SELECT ... INTO ...`, aby przypisać wartość do zmiennej
    SELECT id_autora INTO v_id_autora
    FROM Mapowanie_Uzytkownik_Autor
    WHERE nazwa_uzytkownika_db = USER()
    LIMIT 1; -- Na wszelki wypadek, gdyby coś poszło nie tak

    -- Krok 2: Jeśli znaleziono ID, zwróć jego specjalizacje
    IF v_id_autora IS NOT NULL THEN
        -- To jest zapytanie, które zwraca wynik do użytkownika
        SELECT 
            d.nazwa AS nazwa_dyscypliny
        FROM 
            Autor_Dyscyplina ad
        JOIN 
            Dyscypliny d ON ad.id_dyscypliny = d.id_dyscypliny
        WHERE 
            ad.id_autora = v_id_autora;
    ELSE
        -- Opcjonalnie: Zwróć błąd lub pusty wynik, jeśli użytkownik nie jest zmapowany
        SELECT 'Błąd: Użytkownik nie jest zmapowany do żadnego autora.' AS 'Error';
    END IF;

END$$

DELIMITER ;