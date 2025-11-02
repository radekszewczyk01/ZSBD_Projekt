-- check 02b - Czasopisma, Wydawcy i Kraje
SELECT
    C.tytul AS Czasopismo,
    C.impact_factor,
    W.nazwa AS Wydawca,
    K.nazwa AS Kraj_Wydawcy
FROM
    Czasopismo C
LEFT JOIN
    Wydawca W ON C.id_wydawcy = W.id_wydawcy
LEFT JOIN
    Kraj K ON W.id_kraju = K.id_kraju
ORDER BY
    RAND()
LIMIT 15;