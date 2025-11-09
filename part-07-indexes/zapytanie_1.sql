SET profiling = 1;

--------------------------------------------------
-- Test 1: Brak indeksów
--------------------------------------------------
DROP INDEX idx_prosty_punkty ON Czasopismo_Punkty_Roczne;
DROP INDEX idx_kompozytowy_punkty_rok ON Czasopismo_Punkty_Roczne;

EXPLAIN SELECT COUNT(id_czasopisma) FROM Czasopismo_Punkty_Roczne WHERE punkty_mein = 140 AND rok = 2023;

-- Pomiar
SELECT COUNT(id_czasopisma) FROM Czasopismo_Punkty_Roczne WHERE punkty_mein = 140 AND rok = 2023;
SHOW PROFILES;


--------------------------------------------------
-- Test 2: Indeks PROSTY na punkty_mein
--------------------------------------------------
DROP INDEX idx_prosty_punkty ON Czasopismo_Punkty_Roczne;
DROP INDEX idx_kompozytowy_punkty_rok ON Czasopismo_Punkty_Roczne;

CREATE INDEX idx_prosty_punkty ON Czasopismo_Punkty_Roczne(punkty_mein);

EXPLAIN SELECT COUNT(id_czasopisma) FROM Czasopismo_Punkty_Roczne WHERE punkty_mein = 140 AND rok = 2023;

SELECT COUNT(id_czasopisma) FROM Czasopismo_Punkty_Roczne WHERE punkty_mein = 140 AND rok = 2023;
SHOW PROFILES;

---------------------------------------------------
-- Test 3: Indeks KOMPOZYTOWY na (punkty_mein, rok)
---------------------------------------------------
DROP INDEX idx_prosty_punkty ON Czasopismo_Punkty_Roczne;
DROP INDEX idx_kompozytowy_punkty_rok ON Czasopismo_Punkty_Roczne;

CREATE INDEX idx_kompozytowy_punkty_rok ON Czasopismo_Punkty_Roczne(punkty_mein, rok);

EXPLAIN SELECT COUNT(id_czasopisma) FROM Czasopismo_Punkty_Roczne WHERE punkty_mein = 140 AND rok = 2023;

SELECT COUNT(id_czasopisma) FROM Czasopismo_Punkty_Roczne WHERE punkty_mein = 140 AND rok = 2023;
SHOW PROFILES;

