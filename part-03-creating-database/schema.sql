BEGIN;

-- 0. Kraj, Miasto, Dyscypliny (słownikowe)
CREATE TABLE IF NOT EXISTS Kraj (
  id_kraju SERIAL PRIMARY KEY,
  nazwa VARCHAR(150) UNIQUE NOT NULL
);

CREATE TABLE IF NOT EXISTS Miasto (
  id_miasta SERIAL PRIMARY KEY,
  nazwa VARCHAR(150) NOT NULL,
  id_kraju REFERENCES REFERENCES Kraj(id_kraju) ON UPDATE CASCADE ON DELETE RESTRICT
);

CREATE TABLE IF NOT EXISTS Dyscypliny (
  id_dyscypliny SERIAL PRIMARY KEY,
  nazwa VARCHAR(100) UNIQUE NOT NULL
);

-- 1. Wydawca
CREATE TABLE IF NOT EXISTS Wydawca (
  id_wydawcy SERIAL PRIMARY KEY,
  nazwa VARCHAR(255) UNIQUE NOT NULL,
  id_kraju VARCHAR(100),
  srednia_retrakcji DECIMAL(4,3)
);

-- 2. Czasopismo
CREATE TABLE IF NOT EXISTS Czasopismo (
  id_czasopisma SERIAL PRIMARY KEY,
  tytul VARCHAR(255) UNIQUE NOT NULL,
  impact_factor DECIMAL(5,3),
  czy_otwarty_dostep BOOLEAN,
  id_wydawcy INT REFERENCES Wydawca(id_wydawcy) ON UPDATE CASCADE ON DELETE RESTRICT,
);

-- 3. Afiliacja
CREATE TABLE IF NOT EXISTS Afiliacja (
  id_afiliacji SERIAL PRIMARY KEY,
  nazwa VARCHAR(255) UNIQUE NOT NULL,
  id_miasta INT REFERENCES Miasto(id_miasta) ON UPDATE CASCADE ON DELETE RESTRICT,
);

-- 4. Autor
CREATE TABLE IF NOT EXISTS Autor (
  id_autora SERIAL PRIMARY KEY,
  imie VARCHAR(100),
  nazwisko VARCHAR(150) NOT NULL,
  orcid VARCHAR(50) UNIQUE,
);

-- 5. ZrodloFinansowania
CREATE TABLE IF NOT EXISTS ZrodloFinansowania (
  id_zrodla SERIAL PRIMARY KEY,
  nazwa VARCHAR(255) NOT NULL,
  typ VARCHAR(100),
  id_kraju INT REFERENCES Kraj(id_kraju) ON UPDATE CASCADE ON DELETE RESTRICT
);

-- 7. Artykul
CREATE TABLE IF NOT EXISTS Artykul (
  id_artykulu SERIAL PRIMARY KEY,
  tytul VARCHAR(500) NOT NULL,
  doi VARCHAR(100) UNIQUE NOT NULL,
  rok_publikacji INT NOT NULL,
  punkty_mein INT,
  wspolczynnik_rzetelnosci DECIMAL(4,3),
  data_ostatniej_aktualizacji DATE,
  id_czasopisma INT REFERENCES Czasopisma(id_czasopisma) ON UPDATE CASCADE ON DELETE RESTRICT
);

-- 8. RundaRecenzyjna
CREATE TABLE IF NOT EXISTS RundaRecenzyjna (
    id_rundy SERIAL PRIMARY KEY,
    id_artykulu INT NOT NULL,
    
    numer_rundy INT NOT NULL DEFAULT 1,
    data_rozpoczecia DATE,
    data_zakonczenia DATE,
    decyzja_redaktora VARCHAR(100), -- (np. 'Zaakceptowany', 'Drobne poprawki', 'Odrzucony')
    
    FOREIGN KEY (id_artykulu) REFERENCES Artykul(id_artykulu) 
        ON UPDATE CASCADE 
        ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS Recenzja (
    id_recenzji SERIAL PRIMARY KEY,
    id_rundy INT NOT NULL,
    id_autora_recenzenta INT NOT NULL, 
    
    rekomendacja VARCHAR(100), -- (np. 'Akceptacja', 'Drobne poprawki', 'Odrzucenie')
    tresc_recenzji TEXT,
    data_otrzymania DATE,
    FOREIGN KEY (id_rundy) REFERENCES RundaRecenzyjna(id_rundy) 
        ON UPDATE CASCADE 
        ON DELETE CASCADE, 
    FOREIGN KEY (id_autora_recenzenta) REFERENCES Autor(id_autora) 
        ON UPDATE CASCADE 
        ON DELETE RESTRICT,
    UNIQUE(id_rundy, id_autora_recenzenta)
);

-- 9. Powiazania m:n
CREATE TABLE Artykul_Autor (
    id_artykul_autor INT PRIMARY KEY AUTO_INCREMENT, 

    id_artykulu INT NOT NULL,
    id_autora INT NOT NULL,
    kolejnosc_autora INT,

    FOREIGN KEY (id_artykulu) REFERENCES Artykul(id_artykulu) ON UPDATE CASCADE ON DELETE CASCADE,
    FOREIGN KEY (id_autora) REFERENCES Autor(id_autora) ON UPDATE CASCADE ON DELETE CASCADE,

    UNIQUE(id_artykulu, id_autora) 
);

CREATE TABLE IF NOT EXISTS Artykul_ZrodloFinansowania (
  id_artykulu INT NOT NULL,
  id_zrodla INT NOT NULL,
  PRIMARY KEY (id_artykulu, id_zrodla),
  FOREIGN KEY (id_artykulu) REFERENCES Artykul(id_artykulu) ON UPDATE CASCADE ON DELETE CASCADE,
  FOREIGN KEY (id_zrodla) REFERENCES ZrodloFinansowania(id_zrodla) ON UPDATE CASCADE ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS Artykul_Dyscyplina (
  id_artykulu INT NOT NULL,
  id_dyscypliny INT NOT NULL,
  PRIMARY KEY (id_artykulu, id_dyscypliny),
  FOREIGN KEY (id_artykulu) REFERENCES Artykul(id_artykulu) ON UPDATE CASCADE ON DELETE CASCADE,
  FOREIGN KEY (id_dyscypliny) REFERENCES Dyscypliny(id_dyscypliny) ON UPDATE CASCADE ON DELETE CASCADE
);


CREATE TABLE Artykul_Autor_Afiliacja (
    id_artykul_autor INT NOT NULL,
    id_afiliacji INT NOT NULL,
    PRIMARY KEY (id_artykul_autor, id_afiliacji),
    FOREIGN KEY (id_artykul_autor) 
        REFERENCES Artykul_Autor(id_artykul_autor)
        ON UPDATE CASCADE ON DELETE CASCADE,
    FOREIGN KEY (id_afiliacji) 
        REFERENCES Afiliacja(id_afiliacji)
        ON UPDATE CASCADE ON DELETE RESTRICT 
);


CREATE TABLE IF NOT EXISTS Cytowanie (
  id_cytowania SERIAL PRIMARY KEY,
  id_cytujacego INT REFERENCES Artykul(id_artykulu) ON UPDATE CASCADE ON DELETE CASCADE,
  id_cytowanego INT REFERENCES Artykul(id_artykulu) ON UPDATE CASCADE ON DELETE CASCADE,
  data_zdarzenia DATE
);


COMMIT;