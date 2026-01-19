CREATE VIEW Perspektywa_Redaktora_Prowadzacego AS
SELECT 
    a.tytul, 
    a.doi, 
    rr.numer_rundy,
    ds.nazwa_decyzji AS status_rundy,
    (SELECT COUNT(*) FROM Recenzja r_in WHERE r_in.id_rundy = rr.id_rundy) AS zaproszono,
    (SELECT COUNT(tresc_recenzji) FROM Recenzja r_in WHERE r_in.id_rundy = rr.id_rundy) AS otrzymano
FROM RundaRecenzyjna rr
JOIN Artykul a ON rr.id_artykulu = a.id_artykulu
JOIN Decyzja_Slownik ds ON rr.id_decyzji = ds.id_decyzji
WHERE
    -- Kluczowy warunek: Jestem przypisany do tej rundy
    rr.id_redaktora_prowadzacego = (SELECT id_autora FROM Mapowanie_Uzytkownik_Autor WHERE nazwa_uzytkownika_db = USER())
    AND rr.data_zakonczenia IS NULL;