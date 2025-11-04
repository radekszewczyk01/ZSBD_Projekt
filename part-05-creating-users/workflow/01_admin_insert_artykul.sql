-- Uruchamiany przez admin_db
-- Wymaga zmiennych: @title, @doi
INSERT INTO Artykul (tytul, doi, rok_publikacji, punkty_mein)
VALUES (
    @title,
    @doi,
    YEAR(CURDATE()),
    140
);
SELECT 'Krok 1 (Admin): Pomyślnie dodano artykuł' AS Status, @doi AS DOI;