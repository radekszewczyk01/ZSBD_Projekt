UPDATE Artykul a

-- Połącz tabele, aby znaleźć status
JOIN RundaRecenzyjna rr ON a.id_artykulu = rr.id_artykulu
JOIN Decyzja_Slownik ds ON rr.id_decyzji = ds.id_decyzji

-- Ustaw pole na NULL
SET 
    a.id_czasopisma = NULL

-- Tylko tam, gdzie status to 'Odrzucony'
WHERE 
    ds.nazwa_decyzji = 'Odrzucony';