import re
import os

# --- Konfiguracja ---
plik_wejsciowy = 'insert_poprawiony.sql'  # <-- CZYTA ten plik (z true/false)
plik_wyjsciowy = 'insert_poprawiony_2.sql' # <-- TWORZY ten plik
# --------------------

# --- WZORCE DLA "Zgloszenie_Wstepne" (dodanie NULL) ---
#
# To jest MĄDRZEJSZY, "pancerny" wzorzec.
# Szuka:
# (grupa "asystent", która jest albo 'NULL' albo liczbą)
# \s* -> DOWOLNA ILOŚĆ SPACJI/BIAŁYCH ZNAKÓW
# ,     -> PRZECINEK
# \s* -> DOWOLNA ILOŚĆ SPACJI/BIAŁYCH ZNAKÓW
# (grupa "data", która jest tekstem daty)
#
# (!!!!) TO JEST LINIA, KTÓRĄ NAPRAWIŁEM (!!!!)
pattern_zgloszenie = re.compile(r"(?P<asystent>NULL|\d+)\s*,\s*(?P<data>'\d{4}-\d{2}-\d{2}')")

def main():
    if not os.path.exists(plik_wejsciowy):
        print(f"BŁĄD: Nie mogę znaleźć pliku '{plik_wejsciowy}'!")
        print("Upewnij się, że ten skrypt jest w tym samym folderze.")
        return

    print(f"Rozpoczynam przetwarzanie pliku: {plik_wejsciowy} (Krok 2 - Wersja 'Pancerna')...")
    
    licznik_linii = 0
    licznik_zmian_zgloszenie = 0

    try:
        with open(plik_wejsciowy, 'r', encoding='utf-8') as f_in, \
             open(plik_wyjsciowy, 'w', encoding='utf-8') as f_out:
            
            for line in f_in:
                licznik_linii += 1
                oryginalna_linia = line

                # --- Poprawka "Zgloszenie_Wstepne" (dodanie NULL) ---
                if line.strip().startswith('INSERT INTO "Zgloszenie_Wstepne"'):
                    
                    # Zamień (asystent),(data) na (asystent),NULL,(data)
                    # Używamy \g<asystent> i \g<data> aby odwołać się do nazw grup
                    # Ta zamiana zachowa oryginalne wartości, dodając NULL pomiędzy nimi
                    
                    # (!!!!) TO JEST POPRAWIONA LINIA ZAMIANY (!!!!)
                    line = pattern_zgloszenie.sub(r'\g<asystent>,NULL,\g<data>', line)
                    
                    if oryginalna_linia != line:
                        licznik_zmian_zgloszenie += 1
                
                # Zapisz linię (zmienioną lub nie) do nowego pliku
                f_out.write(line)

        print("\n--- GOTOWE! ---")
        print(f"Pomyślnie przetworzono {licznik_linii} linii.")
        # Jeśli ta liczba jest 0, to znaczy, że wzorzec znowu nic nie znalazł
        print(f"Dokonano zamian w {licznik_zmian_zgloszenie} liniach dla 'Zgloszenie_Wstepne'.")
        print(f"Poprawiony skrypt został zapisany jako: {plik_wyjsciowy}")

    except Exception as e:
        print(f"Wystąpił nieoczekiwany błąd: {e}")

if __name__ == "__main__":
    main()