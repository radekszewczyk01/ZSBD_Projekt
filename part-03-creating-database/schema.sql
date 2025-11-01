BEGIN;

-- 0. Kraj, Miasto, Dyscypliny (słownikowe)
CREATE TABLE IF NOT EXISTS Kraj (
  id_kraju INT PRIMARY KEY AUTO_INCREMENT,
  nazwa VARCHAR(150) UNIQUE NOT NULL
);

CREATE TABLE IF NOT EXISTS Miasto (
  id_miasta INT PRIMARY KEY AUTO_INCREMENT,
  nazwa VARCHAR(150) NOT NULL,
  id_kraju INT,
  FOREIGN KEY (id_kraju) REFERENCES Kraj(id_kraju) ON UPDATE CASCADE ON DELETE RESTRICT
);

CREATE TABLE IF NOT EXISTS Dyscypliny (
  id_dyscypliny INT PRIMARY KEY AUTO_INCREMENT,
  nazwa VARCHAR(100) UNIQUE NOT NULL
);

-- 1. Wydawca
CREATE TABLE IF NOT EXISTS Wydawca (
  id_wydawcy INT PRIMARY KEY AUTO_INCREMENT,
  nazwa VARCHAR(255) UNIQUE NOT NULL,
  id_kraju INT,
  srednia_retrakcji DECIMAL(4,3),
  FOREIGN KEY (id_kraju) REFERENCES Kraj(id_kraju) ON UPDATE CASCADE ON DELETE RESTRICT
);

-- 2. Czasopismo
CREATE TABLE IF NOT EXISTS Czasopismo (
  id_czasopisma INT PRIMARY KEY AUTO_INCREMENT,
  tytul VARCHAR(255) UNIQUE NOT NULL,
  impact_factor DECIMAL(5,3),
  czy_otwarty_dostep BOOLEAN,
  id_wydawcy INT,
  FOREIGN KEY (id_wydawcy) REFERENCES Wydawca(id_wydawcy) ON UPDATE CASCADE ON DELETE RESTRICT
);

-- 3. Afiliacja
CREATE TABLE IF NOT EXISTS Afiliacja (
  id_afiliacji INT PRIMARY KEY AUTO_INCREMENT,
  nazwa VARCHAR(255) UNIQUE NOT NULL,
  id_miasta INT,
  FOREIGN KEY (id_miasta) REFERENCES Miasto(id_miasta) ON UPDATE CASCADE ON DELETE RESTRICT
);

-- 4. Autor
CREATE TABLE IF NOT EXISTS Autor (
  id_autora INT PRIMARY KEY AUTO_INCREMENT,
  imie VARCHAR(100),
  nazwisko VARCHAR(150) NOT NULL,
  orcid VARCHAR(50) UNIQUE
);

CREATE TABLE IF NOT EXISTS TypFinansowania_Slownik (
    id_typu INT PRIMARY KEY AUTO_INCREMENT,
    nazwa_typu VARCHAR(100) UNIQUE NOT NULL
);

-- Przykładowe dane, które możesz dodać
INSERT INTO TypFinansowania_Slownik (nazwa_typu) VALUES
('Grant rządowy'),
('Grant komercyjny'),
('Fundacja'),
('Środki własne uczelni'),
('Współpraca międzynarodowa');

-- 5. ZrodloFinansowania
CREATE TABLE IF NOT EXISTS ZrodloFinansowania (
  id_zrodla INT PRIMARY KEY AUTO_INCREMENT,
  nazwa VARCHAR(255) NOT NULL,
  id_typu INT,
  id_kraju INT,
  FOREIGN KEY (id_kraju) REFERENCES Kraj(id_kraju) ON UPDATE CASCADE ON DELETE RESTRICT,
  FOREIGN KEY (id_typu) REFERENCES TypFinansowania_Slownik(id_typu) ON UPDATE CASCADE ON DELETE RESTRICT
);

-- 6. Artykul
CREATE TABLE IF NOT EXISTS Artykul (
  id_artykulu INT PRIMARY KEY AUTO_INCREMENT,
  tytul VARCHAR(500) NOT NULL,
  doi VARCHAR(100) UNIQUE NOT NULL,
  rok_publikacji INT NOT NULL,
  punkty_mein INT,
  wspolczynnik_rzetelnosci DECIMAL(4,3),
  data_ostatniej_aktualizacji DATE,
  id_czasopisma INT,
  FOREIGN KEY (id_czasopisma) REFERENCES Czasopismo(id_czasopisma) ON UPDATE CASCADE ON DELETE RESTRICT
);


CREATE TABLE IF NOT EXISTS Decyzja_Slownik (
    id_decyzji INT PRIMARY KEY AUTO_INCREMENT,
    nazwa_decyzji VARCHAR(100) UNIQUE NOT NULL
);

INSERT INTO Decyzja_Slownik (nazwa_decyzji) VALUES
('Zaakceptowany'),
('Drobne poprawki'),
('Duże poprawki'),
('Odrzucony'),
('W trakcie');

-- 7. RundaRecenzyjna
CREATE TABLE IF NOT EXISTS RundaRecenzyjna (
    id_rundy INT PRIMARY KEY AUTO_INCREMENT,
    id_artykulu INT NOT NULL,
    numer_rundy INT NOT NULL DEFAULT 1,
    data_rozpoczecia DATE,
    data_zakonczenia DATE,
    id_decyzji INT,
    FOREIGN KEY (id_artykulu) REFERENCES Artykul(id_artykulu) 
        ON UPDATE CASCADE 
        ON DELETE CASCADE,
    FOREIGN KEY (id_decyzji) REFERENCES Decyzja_Slownik(id_decyzji)
        ON UPDATE CASCADE 
        ON DELETE RESTRICT
);

CREATE TABLE IF NOT EXISTS Rekomendacja_Slownik (
    id_rekomendacji INT PRIMARY KEY AUTO_INCREMENT,
    nazwa_rekomendacji VARCHAR(100) UNIQUE NOT NULL
);

INSERT INTO Rekomendacja_Slownik (nazwa_rekomendacji) VALUES
('Akceptacja'),
('Drobne poprawki'),
('Duże poprawki'),
('Odrzucenie');

-- 8. Recenzja
CREATE TABLE IF NOT EXISTS Recenzja (
    id_recenzji INT PRIMARY KEY AUTO_INCREMENT,
    id_rundy INT NOT NULL,
    id_autora_recenzenta INT NOT NULL, 
    id_rekomendacji INT,
    tresc_recenzji TEXT,
    data_otrzymania DATE,
    FOREIGN KEY (id_rundy) REFERENCES RundaRecenzyjna(id_rundy) 
        ON UPDATE CASCADE 
        ON DELETE CASCADE, 
    FOREIGN KEY (id_autora_recenzenta) REFERENCES Autor(id_autora) 
        ON UPDATE CASCADE 
        ON DELETE RESTRICT,
    FOREIGN KEY (id_rekomendacji) REFERENCES Rekomendacja_Slownik(id_rekomendacji)
        ON UPDATE CASCADE 
        ON DELETE RESTRICT,
    UNIQUE(id_rundy, id_autora_recenzenta)
);

-- 9. Powiazania m:n
CREATE TABLE IF NOT EXISTS Artykul_Autor (
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

CREATE TABLE IF NOT EXISTS Artykul_Autor_Afiliacja (
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
  id_cytowania INT PRIMARY KEY AUTO_INCREMENT,
  id_cytujacego INT,
  id_cytowanego INT,
  data_zdarzenia DATE,
  FOREIGN KEY (id_cytujacego) REFERENCES Artykul(id_artykulu) ON UPDATE CASCADE ON DELETE CASCADE,
  FOREIGN KEY (id_cytowanego) REFERENCES Artykul(id_artykulu) ON UPDATE CASCADE ON DELETE CASCADE,
  UNIQUE(id_cytujacego, id_cytowanego)
);

COMMIT;