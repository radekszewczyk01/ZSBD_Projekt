/*--- WYKONAJ JAKO ADMINISTRATOR ---*/
USE rims_v2;

-- Na wszelki wypadek usuń stary trigger o tej nazwie
DROP TRIGGER IF EXISTS trg_Runda_PoZmianieStatusu;

DELIMITER $$

CREATE TRIGGER trg_Runda_PoZmianieStatusu
-- Uruchom trigger PO (AFTER) operacji UPDATE na tabeli RundaRecenzyjna
AFTER UPDATE ON RundaRecenzyjna
-- Wykonaj dla każdego zmienionego wiersza
FOR EACH ROW
BEGIN
    -- Sprawdź, czy status (id_decyzji) FAKTYCZNIE się zmienił
    -- OLD odnosi się do wartości PRZED aktualizacją
    -- NEW odnosi się do wartości PO aktualizacji
    IF OLD.id_decyzji <> NEW.id_decyzji THEN
    
        -- Jeśli tak, zaktualizuj datę w powiązanym artykule
        UPDATE Artykul
        SET 
            data_ostatniej_aktualizacji = CURDATE()
        WHERE 
            -- Znajdź artykuł, którego dotyczy ta runda
            id_artykulu = NEW.id_artykulu;
            
    END IF;
END$$

DELIMITER ;