/*--- WYKONAJ JAKO ADMINISTRATOR ---*/
USE rims_v2;

CREATE OR REPLACE VIEW Perspektywa_Naczelnego_Poczekalnia AS
SELECT 
    zw.id_zgloszenia,
    zw.tytul,
    zw.status_wstepny,
    zw.data_zgloszenia,
    -- Pobieramy imię i nazwisko asystenta, któremu przydzielono zadanie
    (SELECT CONCAT(aut.imie, ' ', aut.nazwisko) 
     FROM Autor aut 
     WHERE aut.id_autora = zw.id_przypisanego_asystenta) AS 'Przypisany Asystent'
FROM Zgloszenie_Wstepne zw

-- Ten JOIN łańcuchem sprawdza, czy zalogowany użytkownik
-- jest redaktorem naczelnym czasopisma, do którego 
-- skierowano to zgłoszenie.
JOIN Czasopismo cz ON zw.id_czasopisma_docelowego = cz.id_czasopisma
JOIN Mapowanie_Uzytkownik_Autor map ON cz.id_redaktora_naczelnego = map.id_autora
WHERE 
    map.nazwa_uzytkownika_db = USER();