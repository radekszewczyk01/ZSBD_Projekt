-- check 04a - Pełny obraz losowego artykułu
SELECT
    A.tytul AS Tytul_Artykulu,
    C.tytul AS Czasopismo,
    CONCAT(AU.imie, ' ', AU.nazwisko) AS Autor,
    AF.nazwa AS Afiliacja_Autora,
    D.nazwa AS Dyscyplina_Artykulu
FROM
    Artykul A
JOIN
    Czasopismo C ON A.id_czasopisma = C.id_czasopisma
JOIN
    Artykul_Autor AA ON A.id_artykulu = AA.id_artykulu
JOIN
    Autor AU ON AA.id_autora = AU.id_autora
JOIN
    Artykul_Autor_Afiliacja AAA ON AA.id_artykul_autor = AAA.id_artykul_autor
JOIN
    Afiliacja AF ON AAA.id_afiliacji = AF.id_afiliacji
JOIN
    Artykul_Dyscyplina AD ON A.id_artykulu = AD.id_artykulu
JOIN
    Dyscypliny D ON AD.id_dyscypliny = D.id_dyscypliny
WHERE
    AA.kolejnosc_autora = 1 -- Pokaż tylko pierwszego autora
ORDER BY
    RAND()
LIMIT 10;