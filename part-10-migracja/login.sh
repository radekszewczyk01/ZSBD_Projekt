#!/bin/bash
#
# SKRYPT DO SZYBKIEGO LOGOWANIA (METODA NIEBEZPIECZNA: PGPASSWORD)
#

# --- Definicje Użytkowników ---
DB_HOST="localhost"
DB_NAME="rims_v2"

# Sprawdź, czy podano argument
if [ -z "$1" ]; then
    echo "BŁĄD: Nie podano użytkownika."
    echo "Użycie: ./login.sh [--olaf | --krystyna | --lukasz | --seba | --anita]"
    exit 1
fi

# Przypisz użytkownika i hasło na podstawie flagi
case "$1" in
    --olaf)
        DB_USER="author_olaf_1"
        DB_PASS="SilneHasloOlaf123!"
        ;;
    --krystyna)
        DB_USER="redaktor_naczelny_krystyna"
        DB_PASS="SuperBezpieczneHaslo987!"
        ;;
    --lukasz)
        DB_USER="author_lukasz_1"
        DB_PASS="ZMIEN_TO_HASLO_LUKASZ_123!"
        ;;
    --seba)
        DB_USER="asystent_sebastian"
        DB_PASS="SuperBezpieczneHaslo99!"
        ;;
    # Dodałem też Anitę, o której zapomniałeś na liście flag
    --anita)
        DB_USER="asystent_anita"
        DB_PASS="SuperBezpieczneHaslo77!"
        ;;
    *)
        echo "BŁĄD: Nieznana flaga '$1'."
        exit 1
        ;;
esac

# --- Wykonanie ---
echo "Trwa logowanie jako: $DB_USER (Używam PGPASSWORD - NIEBEZPIECZNE)"

# Eksportuj hasło do zmiennej środowiskowej CZYTANEJ PRZEZ psql
export PGPASSWORD=$DB_PASS

# Uruchom psql
psql -U $DB_USER -h $DB_HOST -d $DB_NAME

# Natychmiast wyczyść hasło ze zmiennej po wylogowaniu
unset PGPASSWORD

echo "Wylogowano."