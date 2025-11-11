import os
import sys

# --- Konfiguracja ---
PLIK_WEJSCIOWY = 'rims_v2_MIGRACJA.sql'  # Plik, który chcesz podzielić
PLIK_SCHEMATU  = 'rims_v2_SCHEMA.sql'   # Wyjście: Tylko CREATE TABLE, procedury itp.
PLIK_DANYCH    = 'insert.sql'           # Wyjście: Tylko linie INSERT INTO
# --------------------

def podziel_plik_sql():
    # Sprawdź, czy plik wejściowy istnieje
    if not os.path.exists(PLIK_WEJSCIOWY):
        print(f"BŁĄD: Nie znaleziono pliku '{PLIK_WEJSCIOWY}'!")
        print("Upewnij się, że ten skrypt jest w tym samym folderze co Twój plik .sql")
        sys.exit(1)

    print(f"Przetwarzanie pliku '{PLIK_WEJSCIOWY}'...")
    
    licznik_linii_schematu = 0
    licznik_linii_danych = 0

    try:
        # Użyj 'with' do automatycznego zarządzania otwieraniem/zamykaniem plików
        with open(PLIK_WEJSCIOWY, 'r', encoding='utf-8') as f_wejsciowy, \
             open(PLIK_SCHEMATU,  'w', encoding='utf-8') as f_schemat, \
             open(PLIK_DANYCH,    'w', encoding='utf-8') as f_dane:

            # Czytaj plik wejściowy linia po linii (wydajne dla dużych plików)
            for linia in f_wejsciowy:
                
                # Sprawdź, czy linia (po usunięciu białych znaków i zmianie na małe litery)
                # zaczyna się od "insert into".
                if linia.strip().lower().startswith('insert into'):
                    # Jeśli tak, zapisz ją do pliku z danymi
                    f_dane.write(linia)
                    licznik_linii_danych += 1
                else:
                    # W przeciwnym razie, zapisz ją do pliku ze schematem
                    f_schemat.write(linia)
                    licznik_linii_schematu += 1

    except Exception as e:
        print(f"Wystąpił nieoczekiwany błąd: {e}")
        sys.exit(1)

    print("\nGotowe! Plik został pomyślnie podzielony.")
    print(f"  -> Plik schematu (dla modelu): '{PLIK_SCHEMATU}' ({licznik_linii_schematu} linii)")
    print(f"  -> Plik z danymi (INSERTs):   '{PLIK_DANYCH}' ({licznik_linii_danych} linii)")
    print(f"\nOryginalny plik '{PLIK_WEJSCIOWY}' pozostał nienaruszony.")

# Uruchom główną funkcję
if __name__ == "__main__":
    podziel_plik_sql()