SHOW GRANTS;

SELECT 
    ROUTINE_SCHEMA AS 'BazaDanych',
    ROUTINE_NAME AS 'NazwaProcedury'
FROM 
    information_schema.ROUTINES
WHERE 
    ROUTINE_TYPE = 'PROCEDURE'
    -- Opcjonalnie: odfiltruj procedury systemowe, aby zobaczyć tylko swoje
    AND ROUTINE_SCHEMA NOT IN ('mysql', 'information_schema', 'performance_schema', 'sys');


DROP PROCEDURE IF EXISTS sp_PobierzWszystkieMojeArtykuly;

-- jako olaf
CALL sp_Autor_Demo_ZglosDoCzasopisma('Journal of Out Forget');
CALL sp_Autor_Demo_ZglosDoCzasopisma_Poprawne('Journal of Out Forget');
-- jako anita
SELECT rims_v2.fn_SprawdzZgodnoscDyscyplin(3) AS 'Wynik_Kontroli';

CALL sp_Asystent_AkceptujZgloszenie(5);


-- Sprawdź, obecny stan tabeli artykyułów

SELECT * FROM Artykul
ORDER BY id_artykulu DESC
LIMIT 3;


SELECT * FROM RundaRecenzyjna
ORDER BY id_artykulu DESC
LIMIT 3;


-- jako redaktor naczelny krystyna

SELECT id_artykulu, Aktualny_Status, ID_Ostatniej_Rundy, ID_Redaktora_Prowadzacego  FROM Perspektywa_Naczelnego_Artykuly_W_Systemie ORDER BY id_artykulu DESC LIMIT 3;
CALL sp_Naczelny_PrzypiszRedaktoraDoRundy(21980, 1);

-- jako sebastian - redaktor prowadzący

CALL sp_Redaktor_ZnajdzRecenzentow(20001);
CALL sp_Redaktor_ZaprosRecenzenta(21980, 7);
CALL sp_Redaktor_SprawdzStatusyRecenzji(21980);

-- jako lukasz - recenzent
CALL sp_Recenzent_PrzeslijRecenzje(
    53962, 
    'Drobne poprawki', 
    'Artykuł jest bardzo dobry, jednak wymaga drobnych poprawek w sekcji metodologii...'
);


-- jako admin
SELECT id_artykulu, data_ostatniej_aktualizacji  FROM Artykul ORDER BY id_artykulu DESC  LIMIT 3;

-- jako sebastian - redaktor prowadzący
CALL sp_Redaktor_PodejmijDecyzje(21980, 'Odrzucony');

-- jako admin
SELECT id_artykulu, data_ostatniej_aktualizacji  FROM Artykul ORDER BY id_artykulu DESC  LIMIT 3;