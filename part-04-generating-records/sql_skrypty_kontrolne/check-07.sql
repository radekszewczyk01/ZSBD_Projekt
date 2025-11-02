-- check 04b - Proces recenzji dla losowego artykułu
SELECT
    A.tytul AS Tytul_Artykulu,
    RR.numer_rundy,
    DS.nazwa_decyzji AS Decyzja_Rundy,
    CONCAT(REC.imie, ' ', REC.nazwisko) AS Recenzent,
    RS.nazwa_rekomendacji AS Rekomendacja,
    R.tresc_recenzji
FROM
    Artykul A
JOIN
    RundaRecenzyjna RR ON A.id_artykulu = RR.id_artykulu
JOIN
    Decyzja_Slownik DS ON RR.id_decyzji = DS.id_decyzji
JOIN
    Recenzja R ON RR.id_rundy = R.id_rundy
JOIN
    Autor REC ON R.id_autora_recenzenta = REC.id_autora
JOIN
    Rekomendacja_Slownik RS ON R.id_rekomendacji = RS.id_rekomendacji
WHERE
    A.id_artykulu = (SELECT id_artykulu FROM Artykul ORDER BY RAND() LIMIT 1)
ORDER BY
    A.id_artykulu, RR.numer_rundy, R.id_recenzji;