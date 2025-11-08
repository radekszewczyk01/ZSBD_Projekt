CREATE TABLE IF NOT EXISTS Mapowanie_Uzytkownik_Autor (
    -- Przechowuje pełną nazwę użytkownika MySQL, np. 'prof_kowalski@localhost'
    nazwa_uzytkownika_db VARCHAR(193) PRIMARY KEY, 
    id_autora INT NOT NULL UNIQUE, -- Klucz obcy do tabeli Autor
    FOREIGN KEY (id_autora) 
        REFERENCES Autor(id_autora) 
        ON UPDATE CASCADE ON DELETE CASCADE
);