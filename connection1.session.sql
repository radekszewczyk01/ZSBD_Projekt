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