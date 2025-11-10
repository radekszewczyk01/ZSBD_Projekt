-- Używamy "Common Table Expression" (CTE), aby najpierw znaleźć najnowszą rundę dla każdego artykułu
WITH NajnowszaRunda AS (
    SELECT 
        id_artykulu,
        id_decyzji,
        -- Tworzymy numerowany ranking dla każdego artykułu, 
        -- zaczynając od najnowszej rundy (o najwyższym numerze)
        ROW_NUMBER() OVER(
            PARTITION BY id_artykulu 
            ORDER BY numer_rundy DESC
        ) AS 'ranking_rundy'
    FROM 
        RundaRecenzyjna
)
-- Główne zapytanie
SELECT 
    a.id_artykulu,
    a.id_czasopisma,
    
    -- Jeśli artykuł nie ma jeszcze rundy (IFNULL), pokaż 'Brak Rundy'
    -- W przeciwnym razie pokaż nazwę decyzji z najnowszej rundy
    IFNULL(ds.nazwa_decyzji, 'Brak Rundy Recenzyjnej') AS 'Aktualny_Status'
FROM 
    Artykul a
-- Dołączamy TYLKO najnowszą rundę (tam gdzie ranking = 1)
LEFT JOIN 
    NajnowszaRunda nr ON a.id_artykulu = nr.id_artykulu AND nr.ranking_rundy = 1
-- Dołączamy słownik, aby zamienić ID decyzji na tekst
LEFT JOIN 
    Decyzja_Slownik ds ON nr.id_decyzji = ds.id_decyzji
ORDER BY
    a.id_artykulu DESC LIMIT 10;