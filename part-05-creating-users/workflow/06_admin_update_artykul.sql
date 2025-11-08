-- Uruchamiany przez admin_db
-- Wymaga zmiennych: @doi, @id_czasopisma
SET @id_artykulu = (SELECT id_artykulu FROM Artykul WHERE doi = @doi);

UPDATE Artykul
SET id_czasopisma = @id_czasopisma -- Zmienna @id_czasopisma przekazana z BASH
WHERE id_artykulu = @id_artykulu;

SELECT 'Krok 6 (Admin): Artykuł przypisany do czasopisma. Proces zakończony.' AS Status;