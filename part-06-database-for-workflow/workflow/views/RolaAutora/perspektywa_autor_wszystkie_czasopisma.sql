/*--- WYKONAJ JAKO ADMINISTRATOR ---*/
USE rims_v2;

CREATE OR REPLACE VIEW Perspektywa_Autora_Wszystkie_Czasopisma AS
SELECT 
    tytul,
    impact_factor,
    czy_otwarty_dostep
FROM 
    Czasopismo
ORDER BY 
    tytul;