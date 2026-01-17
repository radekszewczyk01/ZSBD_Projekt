-- run scripts in views first
USE rims_v2;

CREATE ROLE IF NOT EXISTS 'RolaAutora';

GRANT SELECT ON rims_v2.Perspektywa_Opublikowane_Artykuly TO 'RolaAutora';
GRANT SELECT ON rims_v2.Perspektywa_Moje_Zgloszenia TO 'RolaAutora';
GRANT SELECT ON rims_v2.Perspektywa_Nazwy_Dyscyplin TO 'RolaAutora';
GRANT EXECUTE ON PROCEDURE rims_v2.sp_PobierzMojeSpecjalizacje TO 'RolaAutora';
GRANT EXECUTE ON PROCEDURE rims_v2.sp_PobierzWszystkieMojeArtykuly TO 'RolaAutora';
GRANT EXECUTE ON PROCEDURE rims_v2.sp_PobierzAutorowDlaDyscypliny TO 'RolaAutora';
GRANT EXECUTE ON PROCEDURE rims_v2.sp_Autor_ZglosArtykul TO 'RolaAutora';
GRANT EXECUTE ON PROCEDURE rims_v2.sp_Autor_Demo_ZglosDoCzasopisma TO 'RolaAutora';
GRANT EXECUTE ON PROCEDURE rims_v2.sp_Autor_Demo_ZglosDoCzasopisma_Poprawne TO 'RolaAutora';
GRANT SELECT ON rims_v2.Perspektywa_Recenzenta_Moje_Zadania TO 'RolaAutora';
GRANT EXECUTE ON PROCEDURE rims_v2.sp_Recenzent_PrzeslijRecenzje TO 'RolaAutora';