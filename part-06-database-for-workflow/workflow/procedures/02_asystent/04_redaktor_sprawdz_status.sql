/*--- WYKONAJ JAKO ADMINISTRATOR ---*/
USE rims_v2;
DROP PROCEDURE IF EXISTS sp_Redaktor_SprawdzStatusyRecenzji;

DELIMITER $$
CREATE PROCEDURE sp_Redaktor_SprawdzStatusyRecenzji(
    IN p_id_rundy INT -- ID rundy, którą chcesz sprawdzić
)
BEGIN
    DECLARE v_id_redaktora_zalogowanego INT;
    DECLARE v_id_redaktora_prowadzacego INT;

    -- Krok 1: Znajdź ID zalogowanego użytkownika
    SELECT id_autora INTO v_id_redaktora_zalogowanego
    FROM Mapowanie_Uzytkownik_Autor
    WHERE nazwa_uzytkownika_db = USER() LIMIT 1;

    -- Krok 2: Sprawdź, kto jest redaktorem prowadzącym tej rundy
    SELECT id_redaktora_prowadzacego INTO v_id_redaktora_prowadzacego
    FROM RundaRecenzyjna
    WHERE id_rundy = p_id_rundy;

    -- Krok 3: Sprawdzenie bezpieczeństwa (Krytyczne!)
    -- Czy to na pewno TY prowadzisz tę rundę?
    IF v_id_redaktora_zalogowanego IS NULL OR v_id_redaktora_zalogowanego <> v_id_redaktora_prowadzacego THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Błąd: Nie jesteś redaktorem prowadzącym tej rundy.';
    END IF;

    -- Krok 4: Jeśli masz uprawnienia, pokaż statusy
    -- Wyświetl wszystkich recenzentów zaproszonych do tej rundy
    SELECT 
        rec.id_recenzji,
        a.imie AS 'Imie_Recenzenta',
        a.nazwisko AS 'Nazwisko_Recenzenta',
        
        -- Użyj IF, aby pokazać czytelny status
        IF(rec.id_rekomendacji IS NULL, 
           'OCZEKUJE NA RECENZJĘ', 
           'RECENZJA PRZESŁANA') AS 'Status',
           
        rs.nazwa_rekomendacji AS 'Rekomendacja',
        rec.data_otrzymania
        
    FROM Recenzja rec
    JOIN Autor a ON rec.id_autora_recenzenta = a.id_autora
    LEFT JOIN Rekomendacja_Slownik rs ON rec.id_rekomendacji = rs.id_rekomendacji
    WHERE rec.id_rundy = p_id_rundy;

END$$
DELIMITER ;