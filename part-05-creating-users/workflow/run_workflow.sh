#!/usr/bin/env bash
set -euo pipefail

# --- Konfiguracja ---
DBNAME="rpc"
HOST="localhost"

# Użytkownicy MySQL
USER_ADMIN="admin_db"
USER_REDAKTOR="redaktor_kowalski"
USER_RECENZENT="dr_nowak"

# === POPRAWKA: Dodaj hasła dla każdego użytkownika ===
# Użyj haseł ze swojego skryptu konfiguracyjnego
PASS_ADMIN="SilneHasloAdmina123!"
PASS_REDAKTOR="SilneHasloRedaktora456!"
PASS_RECENZENT="SilneHasloRecenzenta789!"


# === GŁÓWNA ZMIENNA PROJEKTU ===
ARTICLE_DOI="10.5555/projekt-1762255484"
# ARTICLE_DOI="10.5555/projekt-$(date +%s)"
ARTICLE_TITLE="Nowy artykuł z BASH 12:24:44"
# ARTICLE_TITLE="Nowy artykuł z BASH $(date +%T)"
ID_AUTORA_RECENZENTA=2 # Zakładamy, że dr_nowak ma id_autora = 2
ID_CZASOPISMA_DOCELOWEGO=1 # Zakładamy, że artykuł trafi do czasopisma o id = 1

# === POPRAWKA: Automatyczne wykrywanie ścieżki do skryptu ===
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

# --- Nazwy plików SQL (teraz z pełną ścieżką) ---
SQL_FILE_1="$SCRIPT_DIR/01_admin_insert_artykul.sql"
SQL_FILE_2="$SCRIPT_DIR/02_redaktor_insert_runda.sql"
SQL_FILE_3="$SCRIPT_DIR/03_redaktor_grant.sql"
SQL_FILE_4="$SCRIPT_DIR/04_recenzent_insert_recenzja.sql"
SQL_FILE_5="$SCRIPT_DIR/05_redaktor_finalize.sql"
SQL_FILE_6="$SCRIPT_DIR/06_admin_update_artykul.sql"


# --- Definicje Poleceń SQL ---
# Krok 1: Admin dodaje artykuł
CMD_STEP_1="
SET ROLE 'RolaAdmina';
USE $DBNAME; 
SET @title = '$ARTICLE_TITLE';
SET @doi = '$ARTICLE_DOI';
SOURCE $SQL_FILE_1;
"
# Krok 2: Redaktor tworzy rundę
CMD_STEP_2="
SET ROLE 'RolaRedaktora';
USE $DBNAME; 
SET @doi = '$ARTICLE_DOI';
SOURCE $SQL_FILE_2;
"
# Krok 3: Redaktor nadaje uprawnienia
CMD_STEP_3="
SET ROLE 'RolaRedaktora';
USE $DBNAME; 
SOURCE $SQL_FILE_3;
"
# Krok 4: Recenzent dodaje recenzję
CMD_STEP_4="
SET ROLE 'RolaRecenzenta';
USE $DBNAME; 
SET @doi = '$ARTICLE_DOI';
SET @id_recenzenta = $ID_AUTORA_RECENZENTA;
SOURCE $SQL_FILE_4;
"
# Krok 5: Redaktor finalizuje rundę i odbiera uprawnienia
CMD_STEP_5="
SET ROLE 'RolaRedaktora';
USE $DBNAME; 
SET @doi = '$ARTICLE_DOI';
SOURCE $SQL_FILE_5;
"
# Krok 6: Admin aktualizuje artykuł
CMD_STEP_6="
SET ROLE 'RolaAdmina';
USE $DBNAME; 
SET @doi = '$ARTICLE_DOI';
SET @id_czasopisma = $ID_CZASOPISMA_DOCELOWEGO;
SOURCE $SQL_FILE_6;
"

# --- Funkcja pomocnicza do uruchamiania SQL ---
# === POPRAWKA: Ta funkcja teraz automatycznie wybiera i podaje hasło ===
run_sql_command() {
    local user="$1"
    local sql_command="$2"
    local step_name="$3"
    local password=""

    # Wybierz hasło na podstawie nazwy użytkownika
    if [ "$user" == "$USER_ADMIN" ]; then
        password="$PASS_ADMIN"
    elif [ "$user" == "$USER_REDAKTOR" ]; then
        password="$PASS_REDAKTOR"
    elif [ "$user" == "$USER_RECENZENT" ]; then
        password="$PASS_RECENZENT"
    else
        echo "BŁĄD: Nie znam hasła dla użytkownika $user" >&2
        exit 1
    fi
    
    echo "-----------------------------------------------------"
    echo "➡️  $step_name (Użytkownik: $user)"
    # Usunęliśmy prośbę o hasło
    
    # Łączymy się z serwerem, podając hasło bezpośrednio
    # WAŻNE: Nie ma spacji między -p a zmienną z hasłem!
    mysql -u "$user" -p"$password" -h "$HOST" -e "$sql_command"
    
    echo "✅  Krok zakończony."
    echo "-----------------------------------------------------"
    sleep 1
}

# --- Definicja Funkcji Części 1 ---
run_part_one() {
    echo "Rozpoczynam symulację przepływu recenzyjnego w bazie $DBNAME..."
    echo "Używam unikalnego DOI: $ARTICLE_DOI"

    run_sql_command "$USER_ADMIN"     "$CMD_STEP_1" "Krok 1: Dodanie artykułu"
    run_sql_command "$USER_REDAKTOR"  "$CMD_STEP_2" "Krok 2: Stworzenie rundy"
    run_sql_command "$USER_REDAKTOR"  "$CMD_STEP_3" "Krok 3: Nadanie uprawnień recenzentom"
    run_sql_command "$USER_RECENZENT" "$CMD_STEP_4" "Krok 4: Dodanie recenzji"

    echo "🏁 Część 1 zakończona. Artykuł czeka na finalizację."
    echo "   Aby kontynuować, odkomentuj 'run_part_two' na końcu tego skryptu."
}

# --- Definicja Funkcji Części 2 ---
run_part_two() {
    echo "-----------------------------------------------------"
    echo "Rozpoczynam Część 2: Finalizacja przepływu dla DOI: $ARTICLE_DOI"
    
    run_sql_command "$USER_REDAKTOR"  "$CMD_STEP_5" "Krok 5: Zamknięcie rundy"
    run_sql_command "$USER_ADMIN"     "$CMD_STEP_6" "Krok 6: Aktualizacja artykułu"

    echo "🏁 Symulacja zakończona pomyślnie!"
}


# --- Główny przepływ pracy ---
# run_part_one

# Aby sfinalizować proces, odkomentuj poniższą linię:
run_part_two