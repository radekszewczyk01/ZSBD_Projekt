CREATE TABLE IF NOT EXISTS Asystent_Czasopisma (
    id_asystenta INT NOT NULL,  -- Klucz obcy do tabeli Autor
    id_czasopisma INT NOT NULL, -- Klucz obcy do Czasopismo
    PRIMARY KEY (id_asystenta, id_czasopisma),
    FOREIGN KEY (id_asystenta) REFERENCES Autor(id_autora),
    FOREIGN KEY (id_czasopisma) REFERENCES Czasopismo(id_czasopisma)
);