-- run scripts in views first
USE rims_v2;

CREATE ROLE IF NOT EXISTS 'RolaRecenzenta';

GRANT SELECT ON rims_v2.Perspektywa_Biblioteka TO 'RolaRecenzenta';
GRANT SELECT ON rims_v2.Perspektywa_Recenzenta TO 'RolaRecenzenta';