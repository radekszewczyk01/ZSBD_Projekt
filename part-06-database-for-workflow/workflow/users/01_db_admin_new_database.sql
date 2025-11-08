-- mysql -u root -p

CREATE DATABASE IF NOT EXISTS rims_v2
  CHARACTER SET utf8mb4 
  COLLATE utf8mb4_polish_ci;


CREATE USER IF NOT EXISTS 'nowy_admin'@'localhost' 
  IDENTIFIED BY 'SilneHaslo123!';


GRANT ALL PRIVILEGES ON rims_v2.* TO 'nowy_admin'@'localhost' 
  WITH GRANT OPTION;


-- 1. Pozwól adminowi tworzyć nowych użytkowników
GRANT CREATE USER ON *.* TO 'nowy_admin'@'localhost';

-- 2. Pozwól adminowi na uruchamianie FLUSH PRIVILEGES (wymagane przez procedurę)
GRANT RELOAD ON *.* TO 'nowy_admin'@'localhost';

-- 3. Pozwól adminowi NADAWAĆ 'RolaAutora' innym 
-- (To jest bezpieczniejsze niż dawanie pełnego GRANT OPTION)
GRANT 'RolaAutora' TO 'nowy_admin'@'localhost' WITH ADMIN OPTION;

-- 1. Pozwól 'nowy_admin' na tworzenie nowych użytkowników
GRANT CREATE USER ON *.* TO 'nowy_admin'@'localhost';

-- 2. Pozwól 'nowy_admin' na odświeżanie uprawnień (dla FLUSH PRIVILEGES)
GRANT RELOAD ON *.* TO 'nowy_admin'@'localhost';

-- 3. (KLUCZOWE) Pozwól 'nowy_admin' na nadawanie 'RolaAutora' innym
GRANT 'RolaAutora' TO 'nowy_admin'@'localhost' WITH ADMIN OPTION;

FLUSH PRIVILEGES;

EXIT;

-- mysql -u nowy_admin -p