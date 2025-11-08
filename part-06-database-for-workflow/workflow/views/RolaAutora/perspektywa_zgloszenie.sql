CREATE VIEW Perspektywa_Moje_Zgloszenia AS
SELECT 
    a.id_artykulu,
    a.tytul,
    a.doi,
    rr.numer_rundy,
    ds.nazwa_decyzji AS aktualny_status,
    rr.data_rozpoczecia AS data_rozpoczecia_rundy,
    CONCAT(red_prow.imie, ' ', red_prow.nazwisko) AS redaktor_prowadzacy
FROM 
    Artykul a
JOIN 
    Artykul_Autor aa ON a.id_artykulu = aa.id_artykulu
-- Wymaga tabeli Mapowanie_Uzytkownik_Autor
JOIN 
    Mapowanie_Uzytkownik_Autor map ON aa.id_autora = map.id_autora
JOIN 
    RundaRecenzyjna rr ON a.id_artykulu = rr.id_artykulu
LEFT JOIN 
    Decyzja_Slownik ds ON rr.id_decyzji = ds.id_decyzji
LEFT JOIN 
    Autor red_prow ON rr.id_redaktora_prowadzacego = red_prow.id_autora
WHERE
    -- 1. Artykuł NIE jest opublikowany
    a.id_czasopisma IS NULL
    
    -- 2. Artykuł należy do ZALOGOWANEGO użytkownika
    AND map.nazwa_uzytkownika_db = USER()
    
    -- 3. Pokaż tylko najnowszą (aktywną) rundę
    AND rr.numer_rundy = (
        SELECT MAX(rr_inner.numer_rundy) 
        FROM RundaRecenzyjna rr_inner 
        WHERE rr_inner.id_artykulu = a.id_artykulu
    );