/* =========================================================================
 KROK 1: Zmiany w strukturze tabeli (Wymagane dla Redaktora Naczelnego)
=========================================================================
*/
-- (Zakładam, że ten krok został już wykonany z naszej poprzedniej rozmowy)
-- Jeśli nie, uruchom go ponownie:

/* =========================================================================
 KROK 2: Tworzenie Ról (Grup)
=========================================================================
*/
CREATE ROLE  "RolaAutora";
CREATE ROLE  "RolaAsystenta";
CREATE ROLE  "RolaRedaktoraNaczelnego";
CREATE ROLE  "RolaAdmina";
CREATE ROLE  "RolaRecenzenta";
CREATE ROLE  "RolaRedaktora";

/* =========================================================================
 KROK 3: Tworzenie Użytkowników (Loginów)
=========================================================================
*/
CREATE USER  "author_olaf_1" WITH PASSWORD 'SilneHasloOlaf123!';
CREATE USER  "asystent_anita" WITH PASSWORD 'SuperBezpieczneHaslo77!';
CREATE USER  "redaktor_naczelny_krystyna" WITH PASSWORD 'SuperBezpieczneHaslo987!';
CREATE USER  "asystent_sebastian" WITH PASSWORD 'SuperBezpieczneHaslo99!';
CREATE USER  "author_lukasz_1" WITH PASSWORD 'ZMIEN_TO_HASLO_LUKASZ_123!';

/* =========================================================================
 KROK 4: Przypisanie Użytkowników do Ról (Grup)
=========================================================================
*/
GRANT "RolaAutora" TO "author_olaf_1";
GRANT "RolaAutora" TO "author_lukasz_1";

GRANT "RolaAsystenta" TO "asystent_anita";
GRANT "RolaAsystenta" TO "asystent_sebastian";

GRANT "RolaAutora", "RolaAsystenta", "RolaRedaktoraNaczelnego" TO "redaktor_naczelny_krystyna";

/* =========================================================================
 KROK 5: Czyszczenie tabeli mapowania (KRYTYCZNE!)
=========================================================================
*/
-- Usuwamy '@localhost' z nazw, aby pasowały do "czystych" loginów
UPDATE "Mapowanie_Uzytkownik_Autor"
SET nazwa_uzytkownika_db = REPLACE(nazwa_uzytkownika_db, '@localhost', '')
WHERE nazwa_uzytkownika_db LIKE '%@localhost';

/* =========================================================================
 KROK 6: Nadanie uprawnień Rolom (Grupom) - Wersja POPRAWIONA
=========================================================================
*/

-- --- Uprawnienia dla "RolaAutora" ---
-- (Zakładam, że Widoki (Perspektywa_...) już istnieją)
GRANT SELECT ON "Perspektywa_Opublikowane_Artykuly" TO "RolaAutora";
GRANT SELECT ON "Perspektywa_Moje_Zgloszenia" TO "RolaAutora";
GRANT SELECT ON "Perspektywa_Nazwy_Dyscyplin" TO "RolaAutora";
GRANT SELECT ON "Perspektywa_Recenzenta_Moje_Zadania" TO "RolaAutora";

-- Nadawanie uprawnień do procedur/funkcji z podaniem argumentów
GRANT EXECUTE ON FUNCTION "sp_PobierzMojeSpecjalizacje"() TO "RolaAutora";
GRANT EXECUTE ON FUNCTION "sp_PobierzWszystkieMojeArtykuly"() TO "RolaAutora";
GRANT EXECUTE ON FUNCTION "sp_PobierzAutorowDlaDyscypliny"(character varying) TO "RolaAutora";
GRANT EXECUTE ON PROCEDURE "sp_Autor_ZglosArtykul"(character varying, character varying, integer, integer, text, text) TO "RolaAutora";
GRANT EXECUTE ON PROCEDURE "sp_Autor_Demo_ZglosDoCzasopisma"(character varying) TO "RolaAutora";
GRANT EXECUTE ON PROCEDURE "sp_Autor_Demo_ZglosDoCzasopisma_Poprawne"(character varying) TO "RolaAutora";
GRANT EXECUTE ON PROCEDURE "sp_Recenzent_PrzeslijRecenzje"(integer, character varying, text) TO "RolaAutora";

-- --- Uprawnienia dla "RolaAsystenta" ---
GRANT SELECT ON "Perspektywa_Biblioteka" TO "RolaAsystenta";
GRANT SELECT ON "Perspektywa_Kolejka_Asystenta" TO "RolaAsystenta";
GRANT SELECT ON "Perspektywa_Asystenta_Moje_Rundy" TO "RolaAsystenta";

GRANT EXECUTE ON FUNCTION "fn_SprawdzZgodnoscDyscyplin"(integer) TO "RolaAsystenta";
GRANT EXECUTE ON PROCEDURE "sp_Asystent_AkceptujZgloszenie"(integer) TO "RolaAsystenta";
GRANT EXECUTE ON FUNCTION "sp_Redaktor_ZnajdzRecenzentow"(integer) TO "RolaAsystenta";
GRANT EXECUTE ON PROCEDURE "sp_Redaktor_ZaprosRecenzenta"(integer, integer) TO "RolaAsystenta";
GRANT EXECUTE ON FUNCTION "sp_Redaktor_SprawdzStatusyRecenzji"(integer) TO "RolaAsystenta";
GRANT EXECUTE ON PROCEDURE "sp_Redaktor_PodejmijDecyzje"(integer, character varying) TO "RolaAsystenta";

-- --- Uprawnienia dla "RolaRedaktoraNaczelnego" ---
GRANT SELECT ON "Perspektywa_Naczelnego_Poczekalnia" TO "RolaRedaktoraNaczelnego";
GRANT SELECT ON "Perspektywa_Naczelnego_Artykuly_W_Systemie" TO "RolaRedaktoraNaczelnego";
GRANT SELECT ON "Perspektywa_Naczelnego_Moj_Zespol" TO "RolaRedaktoraNaczelnego";

GRANT EXECUTE ON PROCEDURE "sp_Naczelny_PrzypiszRedaktoraDoRundy"(integer, integer) TO "RolaRedaktoraNaczelnego";

-- --- (Opcjonalnie) Uprawnienia do tworzenia użytkowników ---
-- Rozważ, czy Asystenci lub Redaktorzy Naczelni powinni mieć te prawa
-- GRANT EXECUTE ON PROCEDURE "sp_StworzUzytkownikaAsystenta"(character varying, character varying, integer) TO "RolaRedaktoraNaczelnego";
-- GRANT EXECUTE ON PROCEDURE "sp_StworzUzytkownikaAutora"(character varying, character varying, integer) TO "RolaRedaktoraNaczelnego";
-- GRANT EXECUTE ON PROCEDURE "sp_StworzUzytkownika_RedaktorNaczelny"(character varying, character varying, integer, integer) TO "RolaAdmina"; -- (Tylko dla Admina!)


RAISE NOTICE '--- SKRYPT UPRAWNIEŃ ZAKOŃCZONY POMYŚLNIE ---';