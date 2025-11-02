# Zawartość pliku: python_subscripts/s02_podstawowe_encje.py

import random
from faker import Faker
from mysql.connector import Error as MySQLError # Importujemy, by łapać błędy

def _pobierz_wszystkie_id(cursor, tabela, kolumna_id):
    """
    Pomocnicza funkcja do pobierania listy wszystkich ID z danej tabeli.
    To jest klucz do zarządzania kluczami obcymi.
    """
    try:
        cursor.execute(f"SELECT {kolumna_id} FROM {tabela}")
        wyniki = cursor.fetchall()
        # Przekształcamy listę krotek [(1,), (2,), ...] na listę ID [1, 2, ...]
        lista_id = [item[0] for item in wyniki]
        return lista_id
    except MySQLError as e:
        print(f"Błąd podczas pobierania ID z tabeli {tabela}: {e}")
        return [] # Zwróć pustą listę w razie błędu

def generuj_podstawowe_encje(db, cursor, fake: Faker, fake_en: Faker):
    """
    Generuje dane dla tabel: Dyscypliny, Wydawca, Czasopismo, Afiliacja.
    """
    try:
        # === KROK A: Pobranie niezbędnych kluczy obcych ===
        
        print("Pobieram istniejące ID (Kraje, Miasta) do mapowania kluczy obcych...")
        list_of_kraj_ids = _pobierz_wszystkie_id(cursor, "Kraj", "id_kraju")
        list_of_miasta_ids = _pobierz_wszystkie_id(cursor, "Miasto", "id_miasta")

        if not list_of_kraj_ids or not list_of_miasta_ids:
            print("BŁĄD: Tabela Kraj lub Miasto jest pusta. Uruchom najpierw skrypt s01.")
            return False

        print(f"Pobrano {len(list_of_kraj_ids)} ID krajów i {len(list_of_miasta_ids)} ID miast.")

        # === KROK B: Dyscypliny (dane słownikowe) ===
        
        print("Generowanie dyscyplin...")
        dyscypliny = [
            'Informatyka', 'Medycyna', 'Fizyka', 'Chemia', 'Biologia',
            'Matematyka', 'Ekonomia', 'Prawo', 'Historia', 'Socjologia',
            'Psychologia', 'Filozofia', 'Językoznawstwo', 'Nauki o Ziemi',
            'Inżynieria materiałowa', 'Robotyka', 'Uczenie maszynowe',
            'Astronomia', 'Genetyka', 'Zarządzanie', 'Archeologia'
        ]
        dane_dyscypliny = [(nazwa,) for nazwa in dyscypliny]
        
        sql_dyscypliny = "INSERT INTO Dyscypliny (nazwa) VALUES (%s)"
        cursor.executemany(sql_dyscypliny, dane_dyscypliny)
        print(f"Wstawiono {len(dane_dyscypliny)} dyscyplin.")

        # === KROK C: Wydawca (potrzebuje id_kraju) ===
        
        print("Generowanie 50 wydawców...")
        wydawcy_do_wstawienia = []
        uzyte_nazwy_wydawcow = set()
        for _ in range(50):
            nazwa = fake_en.company() + " Press"
            if nazwa not in uzyte_nazwy_wydawcow:
                uzyte_nazwy_wydawcow.add(nazwa)
                id_kraju = random.choice(list_of_kraj_ids) # Losowanie z pobranej listy
                srednia_retrakcji = round(random.uniform(0.001, 0.05), 3) # Niska wartość
                wydawcy_do_wstawienia.append((nazwa, id_kraju, srednia_retrakcji))

        sql_wydawca = "INSERT INTO Wydawca (nazwa, id_kraju, srednia_retrakcji) VALUES (%s, %s, %s)"
        cursor.executemany(sql_wydawca, wydawcy_do_wstawienia)
        print(f"Wstawiono {len(wydawcy_do_wstawienia)} wydawców.")

        # === KROK D: Czasopismo (potrzebuje id_wydawcy) ===

        # Najpierw musimy pobrać ID wydawców, których PRZED CHWILĄ stworzyliśmy
        print("Pobieram nowe ID wydawców...")
        list_of_wydawca_ids = _pobierz_wszystkie_id(cursor, "Wydawca", "id_wydawcy")
        if not list_of_wydawca_ids:
            print("BŁĄD: Nie można pobrać ID wydawców.")
            return False

        print(f"Generowanie 200 czasopism...")
        czasopisma_do_wstawienia = []
        uzyte_tytuly_czasopism = set()
        for _ in range(200):
            # Tytuły naukowe lepiej generować po angielsku
            tytul = f"Journal of {fake_en.word().capitalize()} {fake_en.word().capitalize()}"
            if tytul not in uzyte_tytuly_czasopism:
                uzyte_tytuly_czasopism.add(tytul)
                impact_factor = round(random.uniform(0.5, 12.0), 3)
                czy_otwarty_dostep = random.choice([True, False])
                id_wydawcy = random.choice(list_of_wydawca_ids) # Losowanie z nowej listy
                czasopisma_do_wstawienia.append((tytul, impact_factor, czy_otwarty_dostep, id_wydawcy))
        
        sql_czasopismo = "INSERT INTO Czasopismo (tytul, impact_factor, czy_otwarty_dostep, id_wydawcy) VALUES (%s, %s, %s, %s)"
        cursor.executemany(sql_czasopismo, czasopisma_do_wstawienia)
        print(f"Wstawiono {len(czasopisma_do_wstawienia)} czasopism.")

        # === KROK E: Afiliacja (potrzebuje id_miasta) ===
        
        print("Generowanie 150 afiliacji...")
        afiliacje_do_wstawienia = []
        uzyte_nazwy_afiliacji = set()
        for _ in range(150):
            # Używamy fake_en dla nazw uniwersytetów
            nazwa = f"{fake_en.city()} University"
            if random.random() > 0.5: # Zróżnicowanie nazw
                 nazwa = f"Institute of {fake_en.word().capitalize()} Research"
            
            if nazwa not in uzyte_nazwy_afiliacji:
                uzyte_nazwy_afiliacji.add(nazwa)
                id_miasta = random.choice(list_of_miasta_ids) # Losowanie z pobranej listy miast
                afiliacje_do_wstawienia.append((nazwa, id_miasta))

        sql_afiliacja = "INSERT INTO Afiliacja (nazwa, id_miasta) VALUES (%s, %s)"
        cursor.executemany(sql_afiliacja, afiliacje_do_wstawienia)
        print(f"Wstawiono {len(afiliacje_do_wstawienia)} afiliacji.")
        
        print("Zakończono generowanie encji podstawowych.")
        return True # Sukces

    except MySQLError as e:
        print(f"WYSTĄPIŁ BŁĄD BAZY DANYCH w s02_podstawowe_encje: {e}")
        return False
    except Exception as e:
        print(f"WYSTĄPIŁ BŁĄD OGÓLNY w s02_podstawowe_encje: {e}")
        return False