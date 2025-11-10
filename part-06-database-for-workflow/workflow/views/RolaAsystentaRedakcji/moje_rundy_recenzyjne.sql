/*--- WYKONAJ JAKO ADMINISTRATOR ---*/
USE rims_v2;

CREATE OR REPLACE VIEW Perspektywa_Asystenta_Moje_Rundy AS
SELECT 
    rr.id_rundy,
    rr.id_artykulu,
    a.tytul AS 'Tytul_Artykulu',
    rr.numer_rundy,
    ds.nazwa_decyzji AS 'Aktualny_Status_Rundy',
    rr.data_rozpoczecia
FROM RundaRecenzyjna rr

-- Dołączamy dane zalogowanego użytkownika
JOIN Mapowanie_Uzytkownik_Autor map 
    ON rr.id_redaktora_prowadzacego = map.id_autora
    
-- Dołączamy dane artykułu, aby znać tytuł
JOIN Artykul a ON rr.id_artykulu = a.id_artykulu

-- Dołączamy słownik, aby znać status
JOIN Decyzja_Slownik ds ON rr.id_decyzji = ds.id_decyzji

-- Najważniejszy warunek: pokaż tylko te rundy, gdzie JA jestem redaktorem prowadzącym
WHERE 
    map.nazwa_uzytkownika_db = USER();