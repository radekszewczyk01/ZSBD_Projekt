CREATE VIEW Perspektywa_Autor_Dyscyplina AS
SELECT 
    d.nazwa AS nazwa_dyscypliny,
    a.imie AS imie_autora,
    a.nazwisko AS nazwisko_autora,
    a.orcid,
    -- Dołączamy ID na wypadek, gdyby były potrzebne do dalszych złączeń
    a.id_autora,
    d.id_dyscypliny
FROM 
    Autor_Dyscyplina ad
-- Dołącz tabelę Autor, aby uzyskać dane autora
JOIN 
    Autor a ON ad.id_autora = a.id_autora
-- Dołącz tabelę Dyscypliny, aby uzyskać nazwę dyscypliny
JOIN 
    Dyscypliny d ON ad.id_dyscypliny = d.id_dyscypliny
-- Sortujemy domyślnie, aby wyniki były czytelne
ORDER BY 
    nazwa_dyscypliny, nazwisko_autora;