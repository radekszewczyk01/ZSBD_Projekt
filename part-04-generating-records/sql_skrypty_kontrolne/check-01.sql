-- check 01 - kraje i miasta
(SELECT
    K.nazwa AS Kraj,
    M.nazwa AS Miasto
FROM
    Kraj K
LEFT JOIN
    Miasto M ON K.id_kraju = M.id_kraju
)
UNION
(SELECT
    K.nazwa AS Kraj,
    M.nazwa AS Miasto
FROM
    Kraj K
RIGHT JOIN
    Miasto M ON K.id_kraju = M.id_kraju
)
LIMIT 20;