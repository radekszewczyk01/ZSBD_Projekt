CALL sp_StworzUzytkownikaAsystenta('asystent_anita', 'SuperBezpieczneHaslo77!', 15);

-- powinien się tym zajmować redaktor naczelny
INSERT INTO Asystent_Czasopisma (id_asystenta, id_czasopisma) 
VALUES (15, 501);