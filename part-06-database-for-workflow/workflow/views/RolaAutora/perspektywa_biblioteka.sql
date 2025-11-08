CREATE VIEW Perspektywa_Biblioteka AS
SELECT 
    a.id_artykulu,
    a.tytul AS tytul_artykulu,
    a.rok_publikacji,
    a.doi,
    
    -- ZMODYFIKOWANA LOGIKA: Punkty pobierane przez JOIN --
    cpr.punkty_mein, 
    
    cz.tytul AS tytul_czasopisma,
    w.nazwa AS wydawca,
    GROUP_CONCAT(DISTINCT d.nazwa SEPARATOR ', ') AS dyscypliny
FROM 
    Artykul a
-- 1. Musi być opublikowany (stąd INNER JOIN do Czasopismo)
JOIN 
    Czasopismo cz ON a.id_czasopisma = cz.id_czasopisma

-- 2. Dołącz punkty MEiN pasujące do czasopisma ORAZ roku publikacji
LEFT JOIN 
    Czasopismo_Punkty_Roczne cpr 
        ON a.id_czasopisma = cpr.id_czasopisma 
        AND a.rok_publikacji = cpr.rok

-- 3. Reszta informacji (Wydawca, Dyscypliny)
LEFT JOIN 
    Wydawca w ON cz.id_wydawcy = w.id_wydawcy
LEFT JOIN 
    Artykul_Dyscyplina ad ON a.id_artykulu = ad.id_artykulu
LEFT JOIN 
    Dyscypliny d ON ad.id_dyscypliny = d.id_dyscypliny
WHERE
    -- Upewniamy się, że bierzemy tylko opublikowane (na wypadek zmiany JOIN na LEFT)
    a.id_czasopisma IS NOT NULL
GROUP BY 
    a.id_artykulu,
    cz.id_czasopisma,
    w.id_wydawcy,
    cpr.punkty_mein; -- Musimy dodać punkty do GROUP BY