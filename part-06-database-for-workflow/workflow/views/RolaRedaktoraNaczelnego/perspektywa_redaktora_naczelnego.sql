CREATE VIEW Perspektywa_Redaktora_Naczelnego AS
SELECT
    a.id_artykulu,
    a.tytul,
    rr.id_rundy,
    rr.numer_rundy,
    ds.nazwa_decyzji AS status_rundy,
    aut.nazwisko AS redaktor_prowadzacy,
    GROUP_CONCAT(rs.nazwa_rekomendacji) AS rekomendacje_recenzentow
FROM Artykul a
JOIN RundaRecenzyjna rr ON a.id_artykulu = rr.id_artykulu
LEFT JOIN Autor aut ON rr.id_redaktora_prowadzacego = aut.id_autora
LEFT JOIN Decyzja_Slownik ds ON rr.id_decyzji = ds.id_decyzji
LEFT JOIN Recenzja r ON rr.id_rundy = r.id_rundy
LEFT JOIN Rekomendacja_Slownik rs ON r.id_rekomendacji = rs.id_rekomendacji
-- (Tu można dodać warunek na czasopismo, którym zarządza EIC)
GROUP BY a.id_artykulu, rr.id_rundy;