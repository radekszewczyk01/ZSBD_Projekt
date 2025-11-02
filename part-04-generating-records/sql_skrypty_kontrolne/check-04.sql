-- check 03a - Autorzy
SELECT
    imie,
    nazwisko,
    orcid
FROM
    Autor
ORDER BY
    (orcid IS NULL) ASC, -- Pokaż najpierw tych z ORCID
    RAND()
LIMIT 15;