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

