#!/usr/bin/env bash
set -euo pipefail

DBNAME="${1:-rims}"
USER="${2:-root}"
HOST="${3:-localhost}"
SQL_FILE="${4:-input_withdrawn.sql}"

if ! command -v mysql >/dev/null 2>&1; then
  echo "Nie znaleziono polecenia mysql. Zainstaluj mysql-client." >&2
  exit 1
fi

if [ ! -f "$SQL_FILE" ]; then
  echo "Nie można znaleźć pliku $SQL_FILE w $(pwd)." >&2
  exit 1
fi

echo "Uruchamiam $SQL_FILE na bazie $DBNAME na $HOST jako $USER z LOCAL INFILE..."
mysql --local-infile=1 -u "$USER" -p -h "$HOST" "$DBNAME" < "$SQL_FILE"

echo "Gotowe. Jeśli nie było błędów, dane powinny być załadowane."