-- Ostatnie 3 rekordy z tabeli Artykul
SELECT id_artykulu, tytul, doi, id_czasopisma FROM Artykul 
ORDER BY id_artykulu DESC 
LIMIT 3;

-- Ostatnie 3 rekordy z tabeli RundaRecenzyjna
SELECT * FROM RundaRecenzyjna 
ORDER BY id_rundy DESC 
LIMIT 3;

-- Ostatnie 3 rekordy z tabeli Recenzja
SELECT id_recenzji, id_rundy, id_autora_recenzenta, id_rekomendacji FROM Recenzja 
ORDER BY id_recenzji DESC 
LIMIT 3;