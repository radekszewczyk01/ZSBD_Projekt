CREATE TABLE Czasopismo_Punkty_Roczne (
    id_czasopisma INT NOT NULL,
    rok INT NOT NULL,
    punkty_mein INT,
    PRIMARY KEY (id_czasopisma, rok),
    FOREIGN KEY (id_czasopisma) REFERENCES Czasopismo(id_czasopisma)
);
