#!/usr/bin/env bash
set -euo pipefail

# Simple helper to run the SQL file with LOCAL INFILE enabled using mysql CLI.
# Usage:
#   bash load_input_article.sh [DBNAME] [USER] [HOST] [SQL_FILE]
# Defaults: DBNAME=rims, USER=root, HOST=localhost, SQL_FILE=connection1.session.sql

DBNAME="${1:-rpc}"
USER="${2:-rpc_admin}"
HOST="${3:-localhost}"
SQL_FILE="${4:-schema.sql}"

if ! command -v mysql >/dev/null 2>&1; then
  echo "mysql CLI not found. Please install mysql-client." >&2
  exit 1
fi

if [ ! -f "$SQL_FILE" ]; then
  echo "Cannot find $SQL_FILE in $(pwd)." >&2
  exit 1
fi

# --local-infile=1 enables LOCAL INFILE on the client side.
echo "Running $SQL_FILE against $DBNAME on $HOST as $USER with LOCAL INFILE enabled..."
mysql --local-infile=1 -u "$USER" -p -h "$HOST" "$DBNAME" < "$SQL_FILE"

echo "Done. If you saw no errors, data should be loaded."