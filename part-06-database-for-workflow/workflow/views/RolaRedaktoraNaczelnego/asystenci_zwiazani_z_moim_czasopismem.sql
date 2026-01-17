/*--- WYKONAJ JAKO ADMINISTRATOR ---*/
USE rims_v2;

CREATE OR REPLACE VIEW Perspektywa_Naczelnego_Moj_Zespol AS
SELECT 
    a.id_autora,
    a.imie,
    a.nazwisko,
    a.orcid
FROM Autor a

-- Znajdź powiązania asystent-czasopismo
JOIN Asystent_Czasopisma ac ON a.id_autora = ac.id_asystenta

-- Znajdź czasopismo, którym zarządza zalogowany użytkownik (Naczelny)
JOIN Czasopismo cz ON ac.id_czasopisma = cz.id_czasopisma
JOIN Mapowanie_Uzytkownik_Autor map ON cz.id_redaktora_naczelnego = map.id_autora
WHERE 
    map.nazwa_uzytkownika_db = USER()
    
    -- Opcjonalnie: wyklucz samego siebie (Naczelnego) z tej listy
    AND a.id_autora != map.id_autora;
