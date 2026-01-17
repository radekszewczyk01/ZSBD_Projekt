/*--- WYKONAJ JAKO ADMINISTRATOR ---*/
USE rims_v2;

ALTER TABLE Czasopismo
-- Dodaj kolumnę na ID autora, domyślnie NULL
ADD COLUMN id_redaktora_naczelnego INT DEFAULT NULL,
    
-- Dodaj klucz obcy, który łączy tę kolumnę z tabelą Autor
ADD FOREIGN KEY (id_redaktora_naczelnego) 
    REFERENCES Autor(id_autora)
    -- Ważne: co się stanie, gdy usuniesz autora?
    -- ON DELETE SET NULL: Jeśli autor zostanie usunięty, pole ustawi się na NULL.
    -- ON DELETE RESTRICT: Nie pozwoli usunąć autora, jeśli jest on redaktorem.
    ON DELETE SET NULL;


CREATE ROLE IF NOT EXISTS 'RolaRedaktoraNaczelnego';
GRANT SELECT ON rims_v2.Perspektywa_Naczelnego_Poczekalnia TO 'RolaRedaktoraNaczelnego';
GRANT SELECT ON rims_v2.Perspektywa_Naczelnego_Artykuly_W_Systemie TO 'RolaRedaktoraNaczelnego';
GRANT SELECT ON rims_v2.Perspektywa_Naczelnego_Moj_Zespol TO 'RolaRedaktoraNaczelnego';
GRANT EXECUTE ON PROCEDURE rims_v2.sp_Naczelny_PrzypiszRedaktoraDoRundy TO 'RolaRedaktoraNaczelnego';