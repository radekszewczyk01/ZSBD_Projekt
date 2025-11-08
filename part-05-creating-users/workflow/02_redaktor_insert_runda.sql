-- Uruchamiany przez redaktor_kowalski
-- Wymaga zmiennej: @doi
SET @id_artykulu = (SELECT id_artykulu FROM Artykul WHERE doi = @doi);
INSERT INTO RundaRecenzyjna (id_artykulu, numer_rundy, data_rozpoczecia)
VALUES (
    @id_artykulu,
    1,
    CURDATE()
);
SELECT 'Krok 2 (Redaktor): Stworzono rundę dla artykułu' AS Status, @doi AS DOI;