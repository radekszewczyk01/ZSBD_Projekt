/*--- WYKONAJ JAKO ADMINISTRATOR ---*/
USE rims_v2;

CREATE OR REPLACE VIEW Perspektywa_Recenzenta_Moje_Zadania AS
SELECT 
    rec.id_recenzji,
    a.tytul AS 'Tytul_Artykulu',
    cz.tytul AS 'Nazwa_Czasopisma',
    rr.numer_rundy
FROM Recenzja rec

-- Dołączamy dane zalogowanego użytkownika
JOIN Mapowanie_Uzytkownik_Autor map 
    ON rec.id_autora_recenzenta = map.id_autora
    
-- Dołączamy dane rundy i artykułu, aby znać szczegóły
JOIN RundaRecenzyjna rr ON rec.id_rundy = rr.id_rundy
JOIN Artykul a ON rr.id_artykulu = a.id_artykulu
JOIN Czasopismo cz ON a.id_czasopisma = cz.id_czasopisma

WHERE 
    -- Warunek 1: Pokaż tylko zadania przypisane do MNIE
    map.nazwa_uzytkownika_db = USER()
    
    -- Warunek 2: Pokaż tylko NIEWYPEŁNIONE zadania
    AND rec.id_rekomendacji IS NULL;

-- Nadaj uprawnienia RoliAutora
