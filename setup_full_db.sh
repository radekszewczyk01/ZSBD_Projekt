#!/bin/bash
set -e

# Configuration
DB_NAME="rpc"
DB_USER="rpc_admin"
DB_PASS="Silnehaslo123."
ROOT_PASS=""

# Paths
PART6_DIR="./part-06-database-for-workflow"
SCHEMA_FILE="$PART6_DIR/schema/schema.sql"
DATA_GENERATOR="$PART6_DIR/data/loading_data.py"

echo "=== MySQL Database Setup Script ==="
echo "This script will create the '$DB_NAME' database and load all structure and data."

echo "Select authentication method for root:"
echo "1) Sudo (Use system root, recommended for Linux)"
echo "2) Password (If you have a set MySQL root password)"
read -p "Choice [1]: " AUTH_CHOICE
AUTH_CHOICE=${AUTH_CHOICE:-1}

if [ "$AUTH_CHOICE" = "2" ]; then
    echo "Please enter your MySQL 'root' password:"
    read -s ROOT_PASS
    ADMIN_CMD="mysql -u root -p$ROOT_PASS"
else
    echo "Using sudo mysql..."
    ADMIN_CMD="sudo mysql"
fi

# 1. Create User and Database
echo "Creating database '$DB_NAME' and user '$DB_USER'..."
$ADMIN_CMD <<EOF
DROP DATABASE IF EXISTS $DB_NAME;
CREATE DATABASE $DB_NAME CHARACTER SET utf8mb4 COLLATE utf8mb4_polish_ci;
CREATE USER IF NOT EXISTS '$DB_USER'@'localhost' IDENTIFIED BY '$DB_PASS';
ALTER USER '$DB_USER'@'localhost' IDENTIFIED BY '$DB_PASS';
GRANT ALL PRIVILEGES ON $DB_NAME.* TO '$DB_USER'@'localhost' WITH GRANT OPTION;
GRANT CREATE USER, CREATE ROLE, RELOAD, ROLE_ADMIN ON *.* TO '$DB_USER'@'localhost';
SET GLOBAL log_bin_trust_function_creators = 1;
FLUSH PRIVILEGES;
EOF

# Function to load sql files with replacement of db name
load_sql() {
    local file=$1
    echo "Loading: $file"
    # Replace 'rims_v2' with 'rpc' and remove explicit 'USE ...' lines locally for piping
    # We use sed to filter out 'USE rims_v2' or 'USE rpc' to ensure we run in the current DB context defined by mysql client
    sed 's/rims_v2/rpc/g' "$file" | mysql -u "$DB_USER" -p"$DB_PASS" "$DB_NAME"
}

# 2. Load Main Schema
echo "--- Loading Main Schema ---"
load_sql "$SCHEMA_FILE"

# 2b. Pre-create Roles
echo "--- Pre-creating Roles ---"
$ADMIN_CMD <<EOF
USE $DB_NAME;
CREATE ROLE IF NOT EXISTS 'RolaAutora';
CREATE ROLE IF NOT EXISTS 'RolaAsystenta';
CREATE ROLE IF NOT EXISTS 'RolaRedaktoraNaczelnego';
CREATE ROLE IF NOT EXISTS 'RolaRecenzenta';
CREATE ROLE IF NOT EXISTS 'RolaAdmina';
CREATE ROLE IF NOT EXISTS 'RolaRedaktora';

-- Fix for Missing Columns (id_redaktora_naczelnego)
-- This column is added in 06_rola_redaktora_naczelnego.sql but required by views earlier
-- We add it here to ensure schema is complete before views are loaded
SET @col_exists := (SELECT COUNT(*) FROM information_schema.columns WHERE table_name = 'Czasopismo' AND column_name = 'id_redaktora_naczelnego' AND table_schema = '$DB_NAME');
SET @sql_col := IF(@col_exists = 0, 'ALTER TABLE Czasopismo ADD COLUMN id_redaktora_naczelnego INT DEFAULT NULL', 'SELECT "Column exists"');
PREPARE stmt_col FROM @sql_col;
EXECUTE stmt_col;
DEALLOCATE PREPARE stmt_col;

SET @fk_exists := (SELECT COUNT(*) FROM information_schema.table_constraints WHERE constraint_name = 'fk_czasopismo_naczelny' AND table_schema = '$DB_NAME');
SET @sql_fk := IF(@fk_exists = 0, 'ALTER TABLE Czasopismo ADD CONSTRAINT fk_czasopismo_naczelny FOREIGN KEY (id_redaktora_naczelnego) REFERENCES Autor(id_autora) ON DELETE SET NULL', 'SELECT "Constraint exists"');
PREPARE stmt_fk FROM @sql_fk;
EXECUTE stmt_fk;
DEALLOCATE PREPARE stmt_fk;

FLUSH PRIVILEGES;
EOF

# 3. Load Workflow Tables
echo "--- Loading Workflow Tables ---"
for f in "$PART6_DIR/workflow/tables"/*.sql; do
    [ -e "$f" ] && load_sql "$f"
done

# 4. Load Functions
echo "--- Loading Functions ---"
for f in "$PART6_DIR/workflow/functions"/*.sql; do
    [ -e "$f" ] && load_sql "$f"
done

# 5. Load Procedures (Recursive)
echo "--- Loading Procedures ---"
find "$PART6_DIR/workflow/procedures" -name "*.sql" | sort | while read f; do
    load_sql "$f"
done

# 6. Load Views (Recursive)
echo "--- Loading Views ---"
find "$PART6_DIR/workflow/views" -name "*.sql" | sort | while read f; do
    load_sql "$f"
done

# 7. Load Triggers
echo "--- Loading Triggers ---"
for f in "$PART6_DIR/workflow/trigger"/*.sql; do
    [ -e "$f" ] && load_sql "$f"
done

# 8. Run Python Data Generator
echo "--- Generating Data (Python) ---"
if [ -f "$DATA_GENERATOR" ]; then
    python3 "$DATA_GENERATOR"
else
    echo "Warning: Data generator not found at $DATA_GENERATOR"
fi

# 9. Load Workflow Users/Roles (Optional - might conflict with generator data but usually required for perms)
echo "--- Loading User/Role Definitions ---"
# Skipping 01_db_admin because we already created admin
for f in "$PART6_DIR/workflow/users"/*.sql; do
    if [[ "$f" != *"01_db_admin_new_database.sql" ]]; then
        load_sql "$f" || echo "Warning: Error loading $f (might be duplicate users)"
    fi
done

echo "=== Setup Complete! ==="
