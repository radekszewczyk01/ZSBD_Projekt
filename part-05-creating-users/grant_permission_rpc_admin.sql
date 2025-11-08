-- - jako root

-- Krok 1: Daj rpc_admin pełną kontrolę NAD BAZĄ DANYCH 'rpc'
-- (włącznie z prawem do nadawania tych uprawnień innym, czyli WITH GRANT OPTION)
GRANT ALL PRIVILEGES ON rpc.* TO 'rpc_admin'@'localhost' WITH GRANT OPTION;

-- Krok 2: Daj rpc_admin globalne uprawnienia do TWORZENIA użytkowników i ról
-- (To jest główny powód Twojego błędu)
GRANT CREATE USER, CREATE ROLE ON *.* TO 'rpc_admin'@'localhost';

-- Krok 3: Daj rpc_admin prawo do NADAWANIA RÓL nowym użytkownikom
-- (Potrzebne do GRANT 'RolaAdmina' TO 'admin_db')
GRANT ROLE_ADMIN ON *.* TO 'rpc_admin'@'localhost';

-- Krok 4: Daj rpc_admin prawo do FLUSH PRIVILEGES
GRANT RELOAD ON *.* TO 'rpc_admin'@'localhost';

-- Krok 5: Zastosuj wszystkie zmiany
FLUSH PRIVILEGES;