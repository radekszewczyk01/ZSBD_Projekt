-- run procedures/01_sp_StworzUzytkownikaAutora.sql first to create the procedure
-- tworzymy uzytkownika dla autora o id 2 - Olaf Łobczyk
CALL sp_StworzUzytkownikaAutora('author_olaf_1', 'SilneHasloOlaf123!', 2);  