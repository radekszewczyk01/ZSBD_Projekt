# Zawartość pliku: python_subscripts/s03_autorzy_finansowanie.py

import random
from faker import Faker
from mysql.connector import Error as MySQLError

def generuj_autorow_i_finansowanie(db, cursor, fake: Faker, fake_en: Faker):
    """
    Generuje dane dla tabel: Autor i ZrodloFinansowania.
    Pobiera klucze obce z Kraj i TypFinansowania_Slownik.
    """
    try:
        # === KROK A: Pobranie niezbędnych kluczy obcych ===
        
        print("Pobieram istniejące ID (Kraje, Typy Finansowania) do mapowania...")
        
        # 1. Pobierz ID Krajów (dla ZrodloFinansowania)
        cursor.execute("SELECT id_kraju FROM Kraj")
        kraj_rows = cursor.fetchall()
        list_of_kraj_ids = [item[0] for item in kraj_rows]
        
        # 2. Pobierz ID Typów Finansowania (ze słownika)
        cursor.execute("SELECT id_typu FROM TypFinansowania_Slownik")
        typ_rows = cursor.fetchall()
        list_of_typ_ids = [item[0] for item in typ_rows]

        if not list_of_kraj_ids:
            print("BŁĄD: Tabela Kraj jest pusta. Uruchom najpierw skrypt s01.")
            return False
        if not list_of_typ_ids:
            print("BŁĄD: Tabela TypFinansowania_Slownik jest pusta. Upewnij się, że została wypełniona (INSERTY).")
            return False

        print(f"Pobrano {len(list_of_kraj_ids)} ID krajów i {len(list_of_typ_ids)} ID typów finansowania.")

        # === KROK B: Autor ===
        
        print("Generowanie 1000 autorów...")
        autorzy_do_wstawienia = []
        uzyte_orcidy = set()
        
        for _ in range(1000):
            # Używamy polskiego Fakera (fake) dla imion i nazwisk
            imie = fake.first_name()
            nazwisko = fake.last_name()
            orcid = None
            
            # Nie każdy autor ma ORCID (np. 70% szans)
            if random.random() < 0.7:
                while True: # Pętla, by zapewnić unikalność
                    # Format: 0000-0000-0000-000X
                    nowy_orcid = (
                        f"{random.randint(0, 9999):04d}-"
                        f"{random.randint(0, 9999):04d}-"
                        f"{random.randint(0, 9999):04d}-"
                        f"{random.randint(0, 999):03d}"
                        f"{random.choice(['X', str(random.randint(0, 9))])}"
                    )
                    if nowy_orcid not in uzyte_orcidy:
                        orcid = nowy_orcid
                        uzyte_orcidy.add(orcid)
                        break
                        
            autorzy_do_wstawienia.append((imie, nazwisko, orcid))

        sql_autor = "INSERT INTO Autor (imie, nazwisko, orcid) VALUES (%s, %s, %s)"
        cursor.executemany(sql_autor, autorzy_do_wstawienia)
        print(f"Wstawiono {len(autorzy_do_wstawienia)} autorów.")

        # === KROK C: ZrodloFinansowania (potrzebuje id_kraju, id_typu) ===
        
        print("Generowanie 100 źródeł finansowania...")
        zrodla_do_wstawienia = []
        uzyte_nazwy_zrodel = set()
        
        for _ in range(100):
            # Używamy angielskiego Fakera (fake_en) dla nazw fundacji
            nazwa = ""
            los = random.random()
            if los < 0.33:
                nazwa = f"{fake_en.company()} Foundation"
            elif los < 0.66:
                nazwa = f"National {fake_en.word().capitalize()} Research Council"
            else:
                nazwa = f"{fake_en.city()} University Research Fund"

            if nazwa not in uzyte_nazwy_zrodel:
                uzyte_nazwy_zrodel.add(nazwa)
                id_typu = random.choice(list_of_typ_ids) # Losowanie z pobranej listy typów
                id_kraju = random.choice(list_of_kraj_ids) # Losowanie z pobranej listy krajów
                
                zrodla_do_wstawienia.append((nazwa, id_typu, id_kraju))

        sql_zrodlo = "INSERT INTO ZrodloFinansowania (nazwa, id_typu, id_kraju) VALUES (%s, %s, %s)"
        cursor.executemany(sql_zrodlo, zrodla_do_wstawienia)
        print(f"Wstawiono {len(zrodla_do_wstawienia)} źródeł finansowania.")
        
        print("Zakończono generowanie autorów i źródeł finansowania.")
        return True # Sukces

    except MySQLError as e:
        print(f"WYSTĄPIŁ BŁĄD BAZY DANYCH w s03_autorzy_finansowanie: {e}")
        return False
    except Exception as e:
        print(f"WYSTĄPIŁ BŁĄD OGÓLNY w s03_autorzy_finansowanie: {e}")
        return False