-- check 04c - Sprawdzenie cytowań
SELECT
    CYTUJACY.tytul AS Tytul_Cytujacego,
    CYTUJACY.rok_publikacji AS Rok_Cytujacego,
    CYTOWANY.tytul AS Tytul_Cytowanego,
    CYTOWANY.rok_publikacji AS Rok_Cytowanego,
    C.data_zdarzenia
FROM
    Cytowanie C
JOIN
    Artykul CYTUJACY ON C.id_cytujacego = CYTUJACY.id_artykulu
JOIN
    Artykul CYTOWANY ON C.id_cytowanego = CYTOWANY.id_artykulu
ORDER BY
    RAND()
LIMIT 10;