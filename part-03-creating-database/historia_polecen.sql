-- Jako root: --
CREATE DATABASE rpc;
CREATE USER 'rpc_admin'@'localhost' IDENTIFIED BY 'Silnehaslo123.';
GRANT ALL PRIVILEGES ON rpc.* TO 'rpc_admin'@'localhost';
FLUSH PRIVILEGES;

-- Jako rpc_admin: --
