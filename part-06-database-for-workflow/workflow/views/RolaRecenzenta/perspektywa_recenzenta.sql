CREATE VIEW Perspektywa_Recenzenta AS
SELECT 
    a.tytul, 
    a.doi, 
    rr.id_rundy, 
    r.id_recenzji
FROM Recenzja r
JOIN RundaRecenzyjna rr ON r.id_rundy = rr.id_rundy
JOIN Artykul a ON rr.id_artykulu = a.id_artykulu
WHERE 
    -- Kluczowy warunek: wiersz jest przypisany do MNIE
    r.id_autora_recenzenta = (SELECT id_autora FROM mapowanie_uzytkownik_autor WHERE nazwa_uzytkownika = USER())
    -- Kluczowy warunek: Runda jest aktywna I jeszcze nie zrecenzowałem
    AND rr.data_zakonczenia IS NULL
    AND r.tresc_recenzji IS NULL;