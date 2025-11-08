-- Wykonaj jako administrator (np. nowy_admin)
USE rims_v2;

-- Usuń stary event, jeśli istnieje, aby uniknąć błędów
DROP EVENT IF EXISTS job_PrzydzielAsystentow;

DELIMITER $$

CREATE EVENT job_PrzydzielAsystentow
-- Uruchamiaj co 1 minutę
ON SCHEDULE EVERY 1 MINUTE
-- Zacznij od teraz
STARTS CURRENT_TIMESTAMP
DO
BEGIN
    -- To jest logiką, która będzie wykonywana co minutę

    -- Znajdź wszystkie zgłoszenia, które czekają na asystenta
    UPDATE Zgloszenie_Wstepne z
    
    -- Ustaw im status "W filtracji" oraz przypisz asystenta
    SET 
        z.status_wstepny = 'W filtracji',
        
        -- Ta pod-procedura znajduje jednego LOSOWEGO asystenta
        -- powiązanego z czasopismem danego zgłoszenia
        z.id_przypisanego_asystenta = (
            SELECT id_asystenta 
            FROM Asystent_Czasopisma a
            WHERE a.id_czasopisma = z.id_czasopisma_docelowego
            ORDER BY RAND() -- Proste losowe rozdzielanie zadań
            LIMIT 1
        )
        
    WHERE 
        -- Warunek 1: Zgłoszenie musi "Oczekiwać"
        z.status_wstepny = 'Oczekuje'
        
        -- Warunek 2: Przydzielamy tylko wtedy, gdy jakiś asystent
        -- DLA TEGO CZASOPISMA w ogóle istnieje w systemie
        AND EXISTS (
            SELECT 1 
            FROM Asystent_Czasopisma a
            WHERE a.id_czasopisma = z.id_czasopisma_docelowego
        );

END$$

DELIMITER ;