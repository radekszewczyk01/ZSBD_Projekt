-- ######################################################
-- Kompleksowy skrypt konfiguracyjny ról i użytkowników
-- Uruchom ten plik jako 'root' lub inny super-administrator
-- ######################################################

-- Ustawienie domyślnej bazy danych (opcjonalnie, ale ułatwia)
USE rpc;

-- --------- Krok 1: Definicje Ról ---------
CREATE ROLE IF NOT EXISTS 'RolaAdmina';
CREATE ROLE IF NOT EXISTS 'RolaRedaktora';
CREATE ROLE IF NOT EXISTS 'RolaRecenzenta';

-- --------- Krok 2: Uprawnienia Admina ---------
GRANT INSERT ON rpc.Artykul TO 'RolaAdmina';
GRANT UPDATE(id_czasopisma) ON rpc.Artykul TO 'RolaAdmina';
GRANT SELECT ON rpc.Artykul TO 'RolaAdmina';
GRANT SELECT ON rpc.RundaRecenzyjna TO 'RolaAdmina';
GRANT SELECT ON rpc.Decyzja_Slownik TO 'RolaAdmina';


-- --------- Krok 3: Uprawnienia Redaktora ---------
GRANT SELECT ON rpc.Artykul TO 'RolaRedaktora';
GRANT INSERT ON rpc.RundaRecenzyjna TO 'RolaRedaktora';
GRANT UPDATE(id_decyzji, data_zakonczenia) ON rpc.RundaRecenzyjna TO 'RolaRedaktora';
GRANT SELECT ON rpc.Recenzja TO 'RolaRedaktora';
GRANT SELECT ON rpc.Decyzja_Slownik TO 'RolaRedaktora';
GRANT SELECT ON rpc.Autor TO 'RolaRedaktora';

-- === Uprawnienie specjalne dla Redaktora ===
GRANT SELECT ON rpc.RundaRecenzyjna 
    TO 'RolaRedaktora' 
    WITH GRANT OPTION;


-- --------- Krok 4: Uprawnienia Recenzenta ---------
GRANT SELECT ON rpc.Artykul TO 'RolaRecenzenta';
GRANT INSERT ON rpc.Recenzja TO 'RolaRecenzenta';
GRANT SELECT ON rpc.Rekomendacja_Slownik TO 'RolaRecenzenta';
GRANT SELECT ON rpc.Autor TO 'RolaRecenzenta';


-- --------- Krok 5: Tworzenie użytkowników (zabezpieczone) ---------
-- Używamy "IF NOT EXISTS", aby skrypt można było uruchamiać wielokrotnie

-- 1. Użytkownik Admin
CREATE USER IF NOT EXISTS 'admin_db'@'localhost' IDENTIFIED BY 'SilneHasloAdmina123!';
GRANT 'RolaAdmina' TO 'admin_db'@'localhost';

-- 2. Użytkownik Redaktor
CREATE USER IF NOT EXISTS 'redaktor_kowalski'@'localhost' IDENTIFIED BY 'SilneHasloRedaktora456!';
GRANT 'RolaRedaktora' TO 'redaktor_kowalski'@'localhost';

-- 3. Użytkownik Recenzent
CREATE USER IF NOT EXISTS 'dr_nowak'@'localhost' IDENTIFIED BY 'SilneHasloRecenzenta789!';
GRANT 'RolaRecenzenta' TO 'dr_nowak'@'localhost';

GRANT USAGE ON rpc.* TO 'RolaAdmina';
GRANT USAGE ON rpc.* TO 'RolaRedaktora';
GRANT USAGE ON rpc.* TO 'RolaRecenzenta';
-- --------- Krok 6: Zastosuj wszystkie zmiany ---------
FLUSH PRIVILEGES;

SELECT 'Sukces: Role, Użytkownicy i Uprawnienia zostały skonfigurowane.' AS 'Status';