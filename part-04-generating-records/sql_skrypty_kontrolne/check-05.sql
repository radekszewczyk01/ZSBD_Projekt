-- check 03b - Źródła Finansowania i ich powiązania
SELECT
    ZF.nazwa AS Nazwa_Zrodla,
    TFS.nazwa_typu AS Typ,
    K.nazwa AS Kraj_Zrodla
FROM
    ZrodloFinansowania ZF
LEFT JOIN
    TypFinansowania_Slownik TFS ON ZF.id_typu = TFS.id_typu
LEFT JOIN
    Kraj K ON ZF.id_kraju = K.id_kraju
ORDER BY
    RAND()
LIMIT 15;