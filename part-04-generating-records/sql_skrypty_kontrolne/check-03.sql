-- check 02c - Dyscypliny (słownik)
SELECT
    nazwa AS Dyscyplina
FROM
    Dyscypliny
ORDER BY
    nazwa
LIMIT 15;