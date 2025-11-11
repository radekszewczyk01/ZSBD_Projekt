import re
import os

# --- Konfiguracja ---
# Upewnij się, że ten plik jest w tym samym folderze co skrypt
plik_wejsciowy = 'insert.sql'
plik_wyjsciowy = 'insert_poprawiony.sql'
# --------------------

# Wyrażenia regularne do znalezienia i zamiany
# Szukamy wzorca: (dowolna liczba z kropką lub bez),(1),(dowolna liczba)
# np. 5.774,1,129  -> zamieni na: 5.774,true,129
pattern_true = re.compile(r'([\d\.]+),(1),(\d+)')

# np. 5.774,0,129  -> zamieni na: 5.774,false,129
pattern_false = re.compile(r'([\d\.]+),(0),(\d+)')


def main():
    # Sprawdzenie, czy plik wejściowy istnieje
    if not os.path.exists(plik_wejsciowy):
        print(f"BŁĄD: Nie mogę znaleźć pliku '{plik_wejsciowy}'!")
        print("Upewnij się, że skrypt Pythona jest w tym samym folderze co Twój plik .sql.")
        return

    print(f"Rozpoczynam przetwarzanie pliku: {plik_wejsciowy}...")
    
    licznik_linii = 0
    licznik_zmian_true = 0
    licznik_zmian_false = 0

    try:
        # Otwieramy oba pliki jednocześnie
        with open(plik_wejsciowy, 'r', encoding='utf-8') as f_in, \
             open(plik_wyjsciowy, 'w', encoding='utf-8') as f_out:
            
            for line in f_in:
                licznik_linii += 1
                oryginalna_linia = line

                # Sprawdzamy, czy to linia, którą chcemy modyfikować
                if line.strip().startswith('INSERT INTO "Czasopismo"'):
                    
                    # Najpierw zamieniamy wszystkie '1' na 'true'
                    # re.sub() znajduje wszystkie wystąpienia wzorca i je zamienia
                    # r'\1,true,\3' odnosi się do grup z wzorca: (grupa 1),true,(grupa 3)
                    line = pattern_true.sub(r'\1,true,\3', line)
                    
                    # Następnie zamieniamy wszystkie '0' na 'false'
                    line = pattern_false.sub(r'\1,false,\3', line)
                    
                    # Liczymy, czy faktycznie dokonaliśmy zmiany
                    if oryginalna_linia != line:
                        if "true" in line:
                            licznik_zmian_true += 1
                        if "false" in line:
                            licznik_zmian_false += 1
                
                # Zapisz linię (zmienioną lub nie) do nowego pliku
                f_out.write(line)

        print("\n--- GOTOWE! ---")
        print(f"Pomyślnie przetworzono {licznik_linii} linii.")
        print(f"Zamieniono '1' na 'true' w {licznik_zmian_true} liniach (dla tabeli Czasopismo).")
        print(f"Zamieniono '0' na 'false' w {licznik_zmian_false} liniach (dla tabeli Czasopismo).")
        print(f"Poprawiony skrypt został zapisany jako: {plik_wyjsciowy}")
        print("\nWAŻNE: Teraz załaduj do bazy plik 'insert_poprawiony.sql'.")

    except Exception as e:
        print(f"Wystąpił nieoczekiwany błąd: {e}")

# Uruchomienie głównej funkcji skryptu
if __name__ == "__main__":
    main()