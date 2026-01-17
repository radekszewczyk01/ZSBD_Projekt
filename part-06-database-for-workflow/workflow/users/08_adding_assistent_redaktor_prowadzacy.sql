CALL sp_StworzUzytkownikaAsystenta('asystent_sebastian', 'SuperBezpieczneHaslo99!', 1);

-- powinien się tym zajmować redaktor naczelny
INSERT INTO Asystent_Czasopisma (id_asystenta, id_czasopisma) 
VALUES (1, 501);