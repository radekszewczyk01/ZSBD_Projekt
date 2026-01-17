/*--- WYKONAJ JAKO ADMINISTRATOR ---*/
USE rims_v2;

CREATE OR REPLACE VIEW Perspektywa_Opublikowane_Artykuly AS
SELECT 
    a.* -- Wybierz wszystkie kolumny z tabeli Artykul
FROM 
    Artykul a
WHERE 
    'Zaakceptowany' = (
        -- Rozpocznij podzapytanie, aby znaleźć status OSTATNIEJ rundy
        SELECT 
            ds.nazwa_decyzji
        FROM 
            RundaRecenzyjna rr
        JOIN 
            Decyzja_Slownik ds ON rr.id_decyzji = ds.id_decyzji
        WHERE 
            rr.id_artykulu = a.id_artykulu -- Połącz z głównym zapytaniem
        ORDER BY 
            rr.numer_rundy DESC -- Sortuj od najnowszej rundy
        LIMIT 1 -- Weź tylko tę najnowszą
    );