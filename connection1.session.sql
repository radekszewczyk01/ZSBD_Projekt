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