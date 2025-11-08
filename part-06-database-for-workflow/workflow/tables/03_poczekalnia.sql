CREATE TABLE IF NOT EXISTS Zgloszenie_Wstepne (
    id_zgloszenia INT PRIMARY KEY AUTO_INCREMENT,
    tytul VARCHAR(500) NOT NULL,
    doi_proponowane VARCHAR(100) UNIQUE NOT NULL,
    rok_proponowany INT NOT NULL,
    
    id_autora_zglaszajacego INT NOT NULL,
    id_czasopisma_docelowego INT NOT NULL,
    
    -- Status "filtracji"
    status_wstepny ENUM('Oczekuje', 'W filtracji', 'Odrzucone', 'Zaakceptowane') DEFAULT 'Oczekuje',
    id_przypisanego_asystenta INT, -- Kto filtruje?
    data_zgloszenia DATE NOT NULL,
    
    FOREIGN KEY (id_autora_zglaszajacego) REFERENCES Autor(id_autora),
    FOREIGN KEY (id_czasopisma_docelowego) REFERENCES Czasopismo(id_czasopisma),
    FOREIGN KEY (id_przypisanego_asystenta) REFERENCES Asystent_Czasopisma(id_asystenta)
);