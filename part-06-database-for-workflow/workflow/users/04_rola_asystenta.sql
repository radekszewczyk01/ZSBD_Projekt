-- run scripts in views first
USE rims_v2;

CREATE ROLE IF NOT EXISTS 'RolaAsystenta';

GRANT SELECT ON rims_v2.Perspektywa_Biblioteka TO 'RolaAsystenta';
GRANT SELECT ON rims_v2.Perspektywa_Kolejka_Asystenta TO 'RolaAsystenta';
GRANT EXECUTE ON FUNCTION rims_v2.fn_SprawdzZgodnoscDyscyplin TO 'RolaAsystenta';
GRANT EXECUTE ON PROCEDURE rims_v2.sp_Asystent_AkceptujZgloszenie TO 'RolaAsystenta';
GRANT EXECUTE ON PROCEDURE rims_v2.sp_Redaktor_ZnajdzRecenzentow TO 'RolaAsystenta';
GRANT SELECT ON rims_v2.Perspektywa_Asystenta_Moje_Rundy TO 'RolaAsystenta';
GRANT EXECUTE ON PROCEDURE rims_v2.sp_Redaktor_ZnajdzRecenzentow TO 'RolaAsystenta';
GRANT EXECUTE ON PROCEDURE rims_v2.sp_Redaktor_ZaprosRecenzenta TO 'RolaAsystenta';
GRANT EXECUTE ON PROCEDURE rims_v2.sp_Redaktor_SprawdzStatusyRecenzji TO 'RolaAsystenta';
GRANT EXECUTE ON PROCEDURE rims_v2.sp_Redaktor_PodejmijDecyzje TO 'RolaAsystenta';
-- (Opcjonalnie) Prawo do podejmowania i odrzucania (jeśli stworzysz te procedury)
-- GRANT EXECUTE ON PROCEDURE rims_v2.sp_Asystent_PodejmijZgloszenie TO 'RolaAsystenta';
-- GRANT EXECUTE ON PROCEDURE rims_v2.sp_Asystent_OdrzucZgloszenie TO 'RolaAsystenta';