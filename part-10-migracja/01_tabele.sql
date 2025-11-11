-- PostgreSQL migration script based on MySQL dump
--
-- Host: localhost    Database: rims_v2
-- ------------------------------------------------------
-- Server version   PostgreSQL (equivalent)


--
-- Tworzenie typu ENUM dla statusu zgłoszenia
--
CREATE TYPE "enum_status_wstepny" AS ENUM ('Oczekuje', 'W filtracji', 'Odrzucone', 'Zaakceptowane');


--
-- Table structure for table "Kraj"
--

DROP TABLE IF EXISTS "Kraj";
CREATE TABLE "Kraj" (
  "id_kraju" SERIAL NOT NULL,
  "nazwa" varchar(150) NOT NULL,
  PRIMARY KEY ("id_kraju"),
  CONSTRAINT "nazwa_kraj_uq" UNIQUE ("nazwa")
) ;

--
-- Dumping data for table "Kraj"
--


--
-- Table structure for table "Miasto"
--

DROP TABLE IF EXISTS "Miasto";
CREATE TABLE "Miasto" (
  "id_miasta" SERIAL NOT NULL,
  "nazwa" varchar(150) NOT NULL,
  "id_kraju" int DEFAULT NULL,
  PRIMARY KEY ("id_miasta"),
  CONSTRAINT "Miasto_ibfk_1" FOREIGN KEY ("id_kraju") REFERENCES "Kraj" ("id_kraju") ON DELETE RESTRICT ON UPDATE CASCADE
) ;
CREATE INDEX "id_kraju_miasto_idx" ON "Miasto" ("id_kraju");

--
-- Dumping data for table "Miasto"
--


--
-- Table structure for table "Afiliacja"
--

DROP TABLE IF EXISTS "Afiliacja";
CREATE TABLE "Afiliacja" (
  "id_afiliacji" SERIAL NOT NULL,
  "nazwa" varchar(255) NOT NULL,
  "id_miasta" int DEFAULT NULL,
  PRIMARY KEY ("id_afiliacji"),
  CONSTRAINT "nazwa_afiliacja_uq" UNIQUE ("nazwa"),
  CONSTRAINT "Afiliacja_ibfk_1" FOREIGN KEY ("id_miasta") REFERENCES "Miasto" ("id_miasta") ON DELETE RESTRICT ON UPDATE CASCADE
) ;
CREATE INDEX "id_miasta_afiliacja_idx" ON "Afiliacja" ("id_miasta");

--
-- Dumping data for table "Afiliacja"
--


--
-- Table structure for table "Wydawca"
--

DROP TABLE IF EXISTS "Wydawca";
CREATE TABLE "Wydawca" (
  "id_wydawcy" SERIAL NOT NULL,
  "nazwa" varchar(255) NOT NULL,
  "id_kraju" int DEFAULT NULL,
  "srednia_retrakcji" decimal(4,3) DEFAULT NULL,
  PRIMARY KEY ("id_wydawcy"),
  CONSTRAINT "nazwa_wydawca_uq" UNIQUE ("nazwa"),
  CONSTRAINT "Wydawca_ibfk_1" FOREIGN KEY ("id_kraju") REFERENCES "Kraj" ("id_kraju") ON DELETE RESTRICT ON UPDATE CASCADE
) ;
CREATE INDEX "id_kraju_wydawca_idx" ON "Wydawca" ("id_kraju");

--
-- Dumping data for table "Wydawca"
--


--
-- Table structure for table "Autor"
--

DROP TABLE IF EXISTS "Autor";
CREATE TABLE "Autor" (
  "id_autora" SERIAL NOT NULL,
  "imie" varchar(100) DEFAULT NULL,
  "nazwisko" varchar(150) NOT NULL,
  "orcid" varchar(50) DEFAULT NULL,
  PRIMARY KEY ("id_autora"),
  CONSTRAINT "orcid_autor_uq" UNIQUE ("orcid")
) ;

--
-- Dumping data for table "Autor"
--


--
-- Table structure for table "Czasopismo"
--

DROP TABLE IF EXISTS "Czasopismo";
CREATE TABLE "Czasopismo" (
  "id_czasopisma" SERIAL NOT NULL,
  "tytul" varchar(255) NOT NULL,
  "impact_factor" decimal(5,3) DEFAULT NULL,
  "czy_otwarty_dostep" BOOLEAN DEFAULT NULL,
  "id_wydawcy" int DEFAULT NULL,
  "id_redaktora_naczelnego" int DEFAULT NULL,
  PRIMARY KEY ("id_czasopisma"),
  CONSTRAINT "tytul_czasopismo_uq" UNIQUE ("tytul"),
  CONSTRAINT "Czasopismo_ibfk_1" FOREIGN KEY ("id_wydawcy") REFERENCES "Wydawca" ("id_wydawcy") ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT "Czasopismo_ibfk_2" FOREIGN KEY ("id_redaktora_naczelnego") REFERENCES "Autor" ("id_autora") ON DELETE SET NULL
) ;
CREATE INDEX "id_wydawcy_czasopismo_idx" ON "Czasopismo" ("id_wydawcy");
CREATE INDEX "id_redaktora_naczelnego_idx" ON "Czasopismo" ("id_redaktora_naczelnego");

--
-- Dumping data for table "Czasopismo"
--


--
-- Table structure for table "Artykul"
--

DROP TABLE IF EXISTS "Artykul";
CREATE TABLE "Artykul" (
  "id_artykulu" SERIAL NOT NULL,
  "tytul" varchar(500) NOT NULL,
  "doi" varchar(100) NOT NULL,
  "rok_publikacji" int NOT NULL,
  "wspolczynnik_rzetelnosci" decimal(4,3) DEFAULT NULL,
  "data_ostatniej_aktualizacji" date DEFAULT NULL,
  "id_czasopisma" int DEFAULT NULL,
  PRIMARY KEY ("id_artykulu"),
  CONSTRAINT "doi_artykul_uq" UNIQUE ("doi"),
  CONSTRAINT "Artykul_ibfk_1" FOREIGN KEY ("id_czasopisma") REFERENCES "Czasopismo" ("id_czasopisma") ON DELETE RESTRICT ON UPDATE CASCADE
) ;
CREATE INDEX "idx_a_czasopismo_rok" ON "Artykul" ("id_czasopisma", "rok_publikacji");

--
-- Dumping data for table "Artykul"
--


--
-- Table structure for table "Artykul_Autor"
--

DROP TABLE IF EXISTS "Artykul_Autor";
CREATE TABLE "Artykul_Autor" (
  "id_artykul_autor" SERIAL NOT NULL,
  "id_artykulu" int NOT NULL,
  "id_autora" int NOT NULL,
  "kolejnosc_autora" int DEFAULT NULL,
  PRIMARY KEY ("id_artykul_autor"),
  CONSTRAINT "id_artykulu_id_autora_uq" UNIQUE ("id_artykulu", "id_autora"),
  CONSTRAINT "Artykul_Autor_ibfk_1" FOREIGN KEY ("id_artykulu") REFERENCES "Artykul" ("id_artykulu") ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT "Artykul_Autor_ibfk_2" FOREIGN KEY ("id_autora") REFERENCES "Autor" ("id_autora") ON DELETE CASCADE ON UPDATE CASCADE
) ;
CREATE INDEX "id_autora_aa_idx" ON "Artykul_Autor" ("id_autora");

--
-- Dumping data for table "Artykul_Autor"
--


--
-- Table structure for table "Artykul_Autor_Afiliacja"
--

DROP TABLE IF EXISTS "Artykul_Autor_Afiliacja";
CREATE TABLE "Artykul_Autor_Afiliacja" (
  "id_artykul_autor" int NOT NULL,
  "id_afiliacji" int NOT NULL,
  PRIMARY KEY ("id_artykul_autor","id_afiliacji"),
  CONSTRAINT "Artykul_Autor_Afiliacja_ibfk_1" FOREIGN KEY ("id_artykul_autor") REFERENCES "Artykul_Autor" ("id_artykul_autor") ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT "Artykul_Autor_Afiliacja_ibfk_2" FOREIGN KEY ("id_afiliacji") REFERENCES "Afiliacja" ("id_afiliacji") ON DELETE RESTRICT ON UPDATE CASCADE
) ;
CREATE INDEX "id_afiliacji_aaa_idx" ON "Artykul_Autor_Afiliacja" ("id_afiliacji");

--
-- Dumping data for table "Artykul_Autor_Afiliacja"
--


--
-- Table structure for table "Dyscypliny"
--

DROP TABLE IF EXISTS "Dyscypliny";
CREATE TABLE "Dyscypliny" (
  "id_dyscypliny" SERIAL NOT NULL,
  "nazwa" varchar(100) NOT NULL,
  PRIMARY KEY ("id_dyscypliny"),
  CONSTRAINT "nazwa_dyscypliny_uq" UNIQUE ("nazwa")
) ;

--
-- Dumping data for table "Dyscypliny"
--


--
-- Table structure for table "Artykul_Dyscyplina"
--

DROP TABLE IF EXISTS "Artykul_Dyscyplina";
CREATE TABLE "Artykul_Dyscyplina" (
  "id_artykulu" int NOT NULL,
  "id_dyscypliny" int NOT NULL,
  PRIMARY KEY ("id_artykulu","id_dyscypliny"),
  CONSTRAINT "Artykul_Dyscyplina_ibfk_1" FOREIGN KEY ("id_artykulu") REFERENCES "Artykul" ("id_artykulu") ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT "Artykul_Dyscyplina_ibfk_2" FOREIGN KEY ("id_dyscypliny") REFERENCES "Dyscypliny" ("id_dyscypliny") ON DELETE CASCADE ON UPDATE CASCADE
) ;
CREATE INDEX "idx_ad_id_dyscypliny" ON "Artykul_Dyscyplina" ("id_dyscypliny");

--
-- Dumping data for table "Artykul_Dyscyplina"
--


--
-- Table structure for table "TypFinansowania_Slownik"
--

DROP TABLE IF EXISTS "TypFinansowania_Slownik";
CREATE TABLE "TypFinansowania_Slownik" (
  "id_typu" SERIAL NOT NULL,
  "nazwa_typu" varchar(100) NOT NULL,
  PRIMARY KEY ("id_typu"),
  CONSTRAINT "nazwa_typu_tf_slownik_uq" UNIQUE ("nazwa_typu")
) ;

--
-- Dumping data for table "TypFinansowania_Slownik"
--


--
-- Table structure for table "ZrodloFinansowania"
--

DROP TABLE IF EXISTS "ZrodloFinansowania";
CREATE TABLE "ZrodloFinansowania" (
  "id_zrodla" SERIAL NOT NULL,
  "nazwa" varchar(255) NOT NULL,
  "id_typu" int DEFAULT NULL,
  "id_kraju" int DEFAULT NULL,
  PRIMARY KEY ("id_zrodla"),
  CONSTRAINT "ZrodloFinansowania_ibfk_1" FOREIGN KEY ("id_kraju") REFERENCES "Kraj" ("id_kraju") ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT "ZrodloFinansowania_ibfk_2" FOREIGN KEY ("id_typu") REFERENCES "TypFinansowania_Slownik" ("id_typu") ON DELETE RESTRICT ON UPDATE CASCADE
) ;
CREATE INDEX "id_kraju_zf_idx" ON "ZrodloFinansowania" ("id_kraju");
CREATE INDEX "id_typu_zf_idx" ON "ZrodloFinansowania" ("id_typu");

--
-- Dumping data for table "ZrodloFinansowania"
--


--
-- Table structure for table "Artykul_ZrodloFinansowania"
--

DROP TABLE IF EXISTS "Artykul_ZrodloFinansowania";
CREATE TABLE "Artykul_ZrodloFinansowania" (
  "id_artykulu" int NOT NULL,
  "id_zrodla" int NOT NULL,
  PRIMARY KEY ("id_artykulu","id_zrodla"),
  CONSTRAINT "Artykul_ZrodloFinansowania_ibfk_1" FOREIGN KEY ("id_artykulu") REFERENCES "Artykul" ("id_artykulu") ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT "Artykul_ZrodloFinansowania_ibfk_2" FOREIGN KEY ("id_zrodla") REFERENCES "ZrodloFinansowania" ("id_zrodla") ON DELETE CASCADE ON UPDATE CASCADE
) ;
CREATE INDEX "id_zrodla_azf_idx" ON "Artykul_ZrodloFinansowania" ("id_zrodla");

--
-- Dumping data for table "Artykul_ZrodloFinansowania"
--


--
-- Table structure for table "Asystent_Czasopisma"
--

DROP TABLE IF EXISTS "Asystent_Czasopisma";
CREATE TABLE "Asystent_Czasopisma" (
  "id_asystenta" int NOT NULL,
  "id_czasopisma" int NOT NULL,
  PRIMARY KEY ("id_asystenta","id_czasopisma"),
  CONSTRAINT "Asystent_Czasopisma_ibfk_1" FOREIGN KEY ("id_asystenta") REFERENCES "Autor" ("id_autora"),
  CONSTRAINT "Asystent_Czasopisma_ibfk_2" FOREIGN KEY ("id_czasopisma") REFERENCES "Czasopismo" ("id_czasopisma")
) ;
CREATE INDEX "id_czasopisma_ac_idx" ON "Asystent_Czasopisma" ("id_czasopisma");

--
-- Dumping data for table "Asystent_Czasopisma"
--


--
-- Table structure for table "Autor_Dyscyplina"
--

DROP TABLE IF EXISTS "Autor_Dyscyplina";
CREATE TABLE "Autor_Dyscyplina" (
  "id_autora" int NOT NULL,
  "id_dyscypliny" int NOT NULL,
  PRIMARY KEY ("id_autora","id_dyscypliny"),
  CONSTRAINT "Autor_Dyscyplina_ibfk_1" FOREIGN KEY ("id_autora") REFERENCES "Autor" ("id_autora") ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT "Autor_Dyscyplina_ibfk_2" FOREIGN KEY ("id_dyscypliny") REFERENCES "Dyscypliny" ("id_dyscypliny") ON DELETE RESTRICT ON UPDATE CASCADE
) ;
CREATE INDEX "id_dyscypliny_ad_idx" ON "Autor_Dyscyplina" ("id_dyscypliny");

--
-- Dumping data for table "Autor_Dyscyplina"
--


--
-- Table structure for table "Cytowanie"
--

DROP TABLE IF EXISTS "Cytowanie";
CREATE TABLE "Cytowanie" (
  "id_cytowania" SERIAL NOT NULL,
  "id_cytujacego" int DEFAULT NULL,
  "id_cytowanego" int DEFAULT NULL,
  "data_zdarzenia" date DEFAULT NULL,
  PRIMARY KEY ("id_cytowania"),
  CONSTRAINT "id_cytujacego_id_cytowanego_uq" UNIQUE ("id_cytujacego", "id_cytowanego"),
  CONSTRAINT "Cytowanie_ibfk_1" FOREIGN KEY ("id_cytujacego") REFERENCES "Artykul" ("id_artykulu") ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT "Cytowanie_ibfk_2" FOREIGN KEY ("id_cytowanego") REFERENCES "Artykul" ("id_artykulu") ON DELETE CASCADE ON UPDATE CASCADE
) ;
CREATE INDEX "id_cytowanego_idx" ON "Cytowanie" ("id_cytowanego");

--
-- Dumping data for table "Cytowanie"
--


--
-- Table structure for table "Czasopismo_Punkty_Roczne"
--

DROP TABLE IF EXISTS "Czasopismo_Punkty_Roczne";
CREATE TABLE "Czasopismo_Punkty_Roczne" (
  "id_czasopisma" int NOT NULL,
  "rok" int NOT NULL,
  "punkty_mein" int DEFAULT NULL,
  PRIMARY KEY ("id_czasopisma","rok"),
  CONSTRAINT "Czasopismo_Punkty_Roczne_ibfk_1" FOREIGN KEY ("id_czasopisma") REFERENCES "Czasopismo" ("id_czasopisma")
) ;
CREATE INDEX "idx_kompozytowy_punkty_rok" ON "Czasopismo_Punkty_Roczne" ("punkty_mein", "rok");

--
-- Dumping data for table "Czasopismo_Punkty_Roczne"
--


--
-- Table structure for table "Decyzja_Slownik"
--

DROP TABLE IF EXISTS "Decyzja_Slownik";
CREATE TABLE "Decyzja_Slownik" (
  "id_decyzji" SERIAL NOT NULL,
  "nazwa_decyzji" varchar(100) NOT NULL,
  PRIMARY KEY ("id_decyzji"),
  CONSTRAINT "nazwa_decyzji_ds_uq" UNIQUE ("nazwa_decyzji")
) ;

--
-- Dumping data for table "Decyzja_Slownik"
--


--
-- Table structure for table "Mapowanie_Uzytkownik_Autor"
--

DROP TABLE IF EXISTS "Mapowanie_Uzytkownik_Autor";
CREATE TABLE "Mapowanie_Uzytkownik_Autor" (
  "nazwa_uzytkownika_db" varchar(193) NOT NULL,
  "id_autora" int NOT NULL,
  PRIMARY KEY ("nazwa_uzytkownika_db"),
  CONSTRAINT "id_autora_mua_uq" UNIQUE ("id_autora"),
  CONSTRAINT "Mapowanie_Uzytkownik_Autor_ibfk_1" FOREIGN KEY ("id_autora") REFERENCES "Autor" ("id_autora") ON DELETE CASCADE ON UPDATE CASCADE
) ;

--
-- Dumping data for table "Mapowanie_Uzytkownik_Autor"
--


--
-- Table structure for table "Rekomendacja_Slownik"
--

DROP TABLE IF EXISTS "Rekomendacja_Slownik";
CREATE TABLE "Rekomendacja_Slownik" (
  "id_rekomendacji" SERIAL NOT NULL,
  "nazwa_rekomendacji" varchar(100) NOT NULL,
  PRIMARY KEY ("id_rekomendacji"),
  CONSTRAINT "nazwa_rekomendacji_rs_uq" UNIQUE ("nazwa_rekomendacji")
) ;

--
-- Dumping data for table "Rekomendacja_Slownik"
--


--
-- Table structure for table "RundaRecenzyjna"
--

DROP TABLE IF EXISTS "RundaRecenzyjna";
CREATE TABLE "RundaRecenzyjna" (
  "id_rundy" SERIAL NOT NULL,
  "id_artykulu" int NOT NULL,
  "numer_rundy" int NOT NULL DEFAULT '1',
  "data_rozpoczecia" date DEFAULT NULL,
  "data_zakonczenia" date DEFAULT NULL,
  "id_decyzji" int DEFAULT NULL,
  "id_redaktora_prowadzacego" int DEFAULT NULL,
  PRIMARY KEY ("id_rundy"),
  CONSTRAINT "RundaRecenzyjna_ibfk_1" FOREIGN KEY ("id_artykulu") REFERENCES "Artykul" ("id_artykulu") ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT "RundaRecenzyjna_ibfk_2" FOREIGN KEY ("id_decyzji") REFERENCES "Decyzja_Slownik" ("id_decyzji") ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT "RundaRecenzyjna_ibfk_3" FOREIGN KEY ("id_redaktora_prowadzacego") REFERENCES "Autor" ("id_autora") ON DELETE RESTRICT ON UPDATE CASCADE
) ;
CREATE INDEX "id_artykulu_rr_idx" ON "RundaRecenzyjna" ("id_artykulu");
CREATE INDEX "id_decyzji_rr_idx" ON "RundaRecenzyjna" ("id_decyzji");
CREATE INDEX "id_redaktora_prowadzacego_rr_idx" ON "RundaRecenzyjna" ("id_redaktora_prowadzacego");


--
-- Dumping data for table "RundaRecenzyjna"
--


--
-- Trigger function and Trigger for table "RundaRecenzyjna"
--
CREATE OR REPLACE FUNCTION update_artykul_aktualizacja_on_decyzja_change()
RETURNS TRIGGER AS $$
BEGIN
    -- Używamy "IS DISTINCT FROM" aby poprawnie obsłużyć wartości NULL
    IF OLD.id_decyzji IS DISTINCT FROM NEW.id_decyzji THEN
        UPDATE "Artykul"
        SET data_ostatniej_aktualizacji = CURRENT_DATE  -- CURDATE() z MySQL to CURRENT_DATE w PostgreSQL
        WHERE id_artykulu = NEW.id_artykulu;
    END IF;
    
    RETURN NEW; -- Wymagane dla wyzwalacza AFTER UPDATE
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_runda_decyzja_change
AFTER UPDATE ON "RundaRecenzyjna"
FOR EACH ROW
EXECUTE FUNCTION update_artykul_aktualizacja_on_decyzja_change();


--
-- Table structure for table "Recenzja"
--

DROP TABLE IF EXISTS "Recenzja";
CREATE TABLE "Recenzja" (
  "id_recenzji" SERIAL NOT NULL,
  "id_rundy" int NOT NULL,
  "id_autora_recenzenta" int NOT NULL,
  "id_rekomendacji" int DEFAULT NULL,
  "tresc_recenzji" text,
  "data_otrzymania" date DEFAULT NULL,
  PRIMARY KEY ("id_recenzji"),
  CONSTRAINT "id_rundy_id_autora_recenzenta_uq" UNIQUE ("id_rundy", "id_autora_recenzenta"),
  CONSTRAINT "Recenzja_ibfk_1" FOREIGN KEY ("id_rundy") REFERENCES "RundaRecenzyjna" ("id_rundy") ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT "Recenzja_ibfk_2" FOREIGN KEY ("id_autora_recenzenta") REFERENCES "Autor" ("id_autora") ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT "Recenzja_ibfk_3" FOREIGN KEY ("id_rekomendacji") REFERENCES "Rekomendacja_Slownik" ("id_rekomendacji") ON DELETE RESTRICT ON UPDATE CASCADE
) ;
CREATE INDEX "id_autora_recenzenta_rec_idx" ON "Recenzja" ("id_autora_recenzenta");
CREATE INDEX "id_rekomendacji_rec_idx" ON "Recenzja" ("id_rekomendacji");

--
-- Dumping data for table "Recenzja"
--


--
-- Table structure for table "Zgloszenie_Wstepne"
--
DROP TABLE IF EXISTS "Zgloszenie_Wstepne";
CREATE TABLE "Zgloszenie_Wstepne" (
  "id_zgloszenia" SERIAL NOT NULL,
  "tytul" varchar(500) NOT NULL,
  "doi_proponowane" varchar(100) NOT NULL,
  "rok_proponowany" int NOT NULL,
  "id_autora_zglaszajacego" int NOT NULL,
  "id_czasopisma_docelowego" int NOT NULL,
  "status_wstepny" "enum_status_wstepny" DEFAULT 'Oczekuje',
  "id_przypisanego_asystenta" int DEFAULT NULL,
  "id_czasopisma_przypisanego_asystenta" int DEFAULT NULL, -- <-- 1. DODANA KOLUMNA
  "data_zgloszenia" date NOT NULL,
  PRIMARY KEY ("id_zgloszenia"),
  CONSTRAINT "doi_proponowane_zw_uq" UNIQUE ("doi_proponowane"),
  CONSTRAINT "Zgloszenie_Wstepne_ibfk_1" FOREIGN KEY ("id_autora_zglaszajacego") REFERENCES "Autor" ("id_autora"),
  CONSTRAINT "Zgloszenie_Wstepne_ibfk_2" FOREIGN KEY ("id_czasopisma_docelowego") REFERENCES "Czasopismo" ("id_czasopisma"),
  -- 2. ZMODYFIKOWANY KLUCZ OBCY (TERAZ ZŁOŻONY)
  CONSTRAINT "Zgloszenie_Wstepne_ibfk_3" FOREIGN KEY ("id_przypisanego_asystenta", "id_czasopisma_przypisanego_asystenta") REFERENCES "Asystent_Czasopisma" ("id_asystenta", "id_czasopisma")
) ;
CREATE INDEX "id_autora_zglaszajacego_zw_idx" ON "Zgloszenie_Wstepne" ("id_autora_zglaszajacego");
CREATE INDEX "id_czasopisma_docelowego_zw_idx" ON "Zgloszenie_Wstepne" ("id_czasopisma_docelowego");

-- 3. ZMODYFIKOWANY INDEKS (ABY PASOWAŁ DO KLUCZA OBCEGO)
CREATE INDEX "id_przypisanego_asystenta_zw_idx" ON "Zgloszenie_Wstepne" ("id_przypisanego_asystenta", "id_czasopisma_przypisanego_asystenta");


--
-- Dumping data for table "Zgloszenie_Wstepne"
--
--
-- Dumping data for table "Zgloszenie_Wstepne"
--


--
-- Table structure for table "Zgloszenie_Wstepne_Autor"
--

DROP TABLE IF EXISTS "Zgloszenie_Wstepne_Autor";
CREATE TABLE "Zgloszenie_Wstepne_Autor" (
  "id_zgloszenia" int NOT NULL,
  "id_autora" int NOT NULL,
  "kolejnosc_autora" int DEFAULT NULL,
  PRIMARY KEY ("id_zgloszenia","id_autora"),
  CONSTRAINT "Zgloszenie_Wstepne_Autor_ibfk_1" FOREIGN KEY ("id_zgloszenia") REFERENCES "Zgloszenie_Wstepne" ("id_zgloszenia") ON DELETE CASCADE,
  CONSTRAINT "Zgloszenie_Wstepne_Autor_ibfk_2" FOREIGN KEY ("id_autora") REFERENCES "Autor" ("id_autora")
) ;
CREATE INDEX "id_autora_zwa_idx" ON "Zgloszenie_Wstepne_Autor" ("id_autora");

--
-- Dumping data for table "Zgloszenie_Wstepne_Autor"
--


--
-- Table structure for table "Zgloszenie_Wstepne_Dyscyplina"
--

DROP TABLE IF EXISTS "Zgloszenie_Wstepne_Dyscyplina";
CREATE TABLE "Zgloszenie_Wstepne_Dyscyplina" (
  "id_zgloszenia" int NOT NULL,
  "id_dyscypliny" int NOT NULL,
  PRIMARY KEY ("id_zgloszenia","id_dyscypliny"),
  CONSTRAINT "Zgloszenie_Wstepne_Dyscyplina_ibfk_1" FOREIGN KEY ("id_zgloszenia") REFERENCES "Zgloszenie_Wstepne" ("id_zgloszenia") ON DELETE CASCADE,
  CONSTRAINT "Zgloszenie_Wstepne_Dyscyplina_ibfk_2" FOREIGN KEY ("id_dyscypliny") REFERENCES "Dyscypliny" ("id_dyscypliny")
) ;
CREATE INDEX "id_dyscypliny_zwd_idx" ON "Zgloszenie_Wstepne_Dyscyplina" ("id_dyscypliny");

--
-- Dumping data for table "Zgloszenie_Wstepne_Dyscyplina"
--

--
-- UWAGA: Oryginalny plik zawierał tymczasowe struktury widoków (np. "Perspektywa_Asystenta_Moje_Rundy"),
-- ale nie zawierał ich pełnych definicji (CREATE VIEW ...).
-- Z tego powodu nie zostały one uwzględnione w skrypcie migracyjnym.
--