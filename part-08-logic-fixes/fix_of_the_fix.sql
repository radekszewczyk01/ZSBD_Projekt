UPDATE Artykul a

-- Połącz tabele, aby znaleźć status
JOIN RundaRecenzyjna rr ON a.id_artykulu = rr.id_artykulu
JOIN Decyzja_Slownik ds ON rr.id_decyzji = ds.id_decyzji

-- Ustaw pole na LOSOWE ID Czasopisma
SET 
    a.id_czasopisma = (
        SELECT id_czasopisma 
        FROM Czasopismo
        ORDER BY RAND()
        LIMIT 1
    )

-- Tylko tam, gdzie status to 'Odrzucony'
WHERE 
    ds.nazwa_decyzji = 'Odrzucony';