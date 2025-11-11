UPDATE "Zgloszenie_Wstepne" z
SET 
    status_wstepny = 'W filtracji',
    id_przypisanego_asystenta = (
        SELECT id_asystenta 
        FROM "Asystent_Czasopisma" a
        WHERE a.id_czasopisma = z.id_czasopisma_docelowego
        ORDER BY RANDOM() -- RAND() z MySQL to RANDOM() w PostgreSQL
        LIMIT 1
    )
WHERE 
    z.status_wstepny = 'Oczekuje'
    AND EXISTS (
        SELECT 1 
        FROM "Asystent_Czasopisma" a
        WHERE a.id_czasopisma = z.id_czasopisma_docelowego
    );