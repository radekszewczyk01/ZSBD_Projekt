#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Kompletny skrypt do generowania danych testowych dla bazy 'rpc'.

Ten skrypt łączy wszystkie poprzednie moduły (s01-s04) w jeden plik
i jest dostosowany do nowej, znormalizowanej schemy.

UWAGA: Generuje dużą ilość danych (tysiące autorów, dziesiątki tysięcy artykułów)
w celu umożliwienia testowania wydajności indeksów.
Upewnij się, że masz zainstalowane wymagane biblioteki:
pip install mysql-connector-python Faker tqdm
"""

import mysql.connector
from mysql.connector import Error as MySQLError
from faker import Faker
import random
import datetime
import sys

# Opcjonalny import tqdm dla pasków postępu
try:
    from tqdm import tqdm
except ImportError:
    print("Biblioteka 'tqdm' nie znaleziona. Paski postępu będą wyłączone.")
    print("Zainstaluj ją (pip install tqdm) dla lepszego doświadczenia.")
    # Tworzymy fałszywą funkcję tqdm, która po prostu zwraca iterator
    tqdm = lambda x, **kwargs: x

# === KONFIGURACJA ILOŚCI DANYCH ===
# Dostosuj te wartości, aby kontrolować ilość generowanych danych
LICZBA_KRAJOW = 150
LICZBA_WYDAWCOW = 100
LICZBA_CZASOPISM = 500
LICZBA_AFILIACJI = 300
LICZBA_AUTOROW = 5000       # Zwiększone dla testów indeksów
LICZBA_ZRODEL = 200
LICZBA_ARTYKULOW = 20000     # Zwiększone dla testów indeksów
SZANSA_NA_FINANSOWANIE = 0.4
SZANSA_NA_DRUGA_RUNDE = 0.3

# === FUNKCJE POMOCNICZE ===

def _pobierz_wszystkie_id(cursor, tabela, kolumna_id):
    """Pomocnik: Pobiera listę wszystkich ID z danej tabeli."""
    try:
        cursor.execute(f"SELECT {kolumna_id} FROM {tabela}")
        wyniki = cursor.fetchall()
        lista_id = [item[0] for item in wyniki]
        if not lista_id:
            print(f"OSTRZEŻENIE: Tabela {tabela} jest pusta lub nie zwróciła ID.")
        return lista_id
    except MySQLError as e:
        print(f"Błąd podczas pobierania ID z tabeli {tabela}: {e}")
        return []

def _pobierz_id_slownika(cursor, tabela, kolumna_nazwa, kolumna_id):
    """Pomocnik: Pobiera słownik mapujący Nazwa -> ID."""
    try:
        cursor.execute(f"SELECT {kolumna_nazwa}, {kolumna_id} FROM {tabela}")
        wyniki = cursor.fetchall()
        slownik = {nazwa: id_val for nazwa, id_val in wyniki}
        if not slownik:
             print(f"OSTRZEŻENIE: Słownik {tabela} jest pusty.")
        return slownik
    except MySQLError as e:
        print(f"Błąd podczas pobierania słownika {tabela}: {e}")
        return {}

def _generuj_date(start_year=2000, end_year=2024):
    """Generuje losową datę."""
    try:
        year = random.randint(start_year, end_year)
        month = random.randint(1, 12)
        day = random.randint(1, 28) # Uproszczenie dla bezpieczeństwa
        return datetime.date(year, month, day)
    except ValueError:
        # Obsługa przypadku, gdy start_year > end_year (np. przy generowaniu daty cytowania)
        return datetime.date(end_year, 1, 1)


# === MODUŁ 1: KRAJE I MIASTA ===

def generuj_kraje_miasta(db, cursor, fake: Faker, liczba_krajow):
    """
    Generuje kraje i miasta.
    """
    try:
        print(f"Rozpoczynam generowanie {liczba_krajow} krajów...")
        uzyte_nazwy_krajow = set()
        kraje_do_wstawienia = [] # (nazwa_kraju,)

        while len(kraje_do_wstawienia) < liczba_krajow:
            nazwa_kraju = fake.country()
            if nazwa_kraju not in uzyte_nazwy_krajow:
                uzyte_nazwy_krajow.add(nazwa_kraju)
                kraje_do_wstawienia.append((nazwa_kraju,))

        sql_kraj = "INSERT INTO Kraj (nazwa) VALUES (%s)"
        cursor.executemany(sql_kraj, kraje_do_wstawienia)
        print(f"Wstawiono {cursor.rowcount} krajów.")

        # Pobieranie ID wstawionych krajów
        # Używamy executemany, więc lastrowid zwróci ID *pierwszego* wstawionego wiersza
        pierwszy_id_kraju = cursor.lastrowid
        if pierwszy_id_kraju is None:
             print("BŁĄD: Nie udało się pobrać ID ostatnio wstawionego kraju.")
             return False
        
        wszystkie_id_krajow = list(range(pierwszy_id_kraju, pierwszy_id_kraju + len(kraje_do_wstawienia)))
        
        print("Rozpoczynam generowanie miast (od 5 do 15 dla każdego kraju)...")
        miasta_do_wstawienia = [] # (nazwa_miasta, id_kraju)
        licznik_miast = 0

        for id_kraju in wszystkie_id_krajow:
            liczba_miast_dla_kraju = random.randint(5, 15)
            for _ in range(liczba_miast_dla_kraju):
                nazwa_miasta = fake.city()
                miasta_do_wstawienia.append((nazwa_miasta, id_kraju))
                licznik_miast += 1

        if miasta_do_wstawienia:
            sql_miasto = "INSERT INTO Miasto (nazwa, id_kraju) VALUES (%s, %s)"
            cursor.executemany(sql_miasto, miasta_do_wstawienia)
            print(f"Wstawiono łącznie {licznik_miast} miast.")
        
        print("Zakończono: Kraje i Miasta.")
        return True
    except Exception as e:
        print(f"WYSTĄPIŁ BŁĄD w generuj_kraje_miasta: {e}")
        db.rollback()
        return False

# === MODUŁ 2: PODSTAWOWE ENCJE I PUNKTY ===

def generuj_podstawowe_encje(db, cursor, fake: Faker, fake_en: Faker, 
                              liczba_wydawcow, liczba_czasopism, liczba_afiliacji):
    """
    Generuje dane dla: Dyscypliny, Wydawca, Czasopismo, Czasopismo_Punkty_Roczne, Afiliacja.
    """
    try:
        # === A: Pobranie kluczy obcych ===
        print("Pobieram istniejące ID (Kraje, Miasta) do mapowania kluczy obcych...")
        list_of_kraj_ids = _pobierz_wszystkie_id(cursor, "Kraj", "id_kraju")
        list_of_miasta_ids = _pobierz_wszystkie_id(cursor, "Miasto", "id_miasta")

        if not list_of_kraj_ids or not list_of_miasta_ids:
            print("BŁĄD: Tabela Kraj lub Miasto jest pusta. Uruchom najpierw generuj_kraje_miasta.")
            return False

        # === B: Dyscypliny (słownik) ===
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

        # === C: Wydawca (potrzebuje id_kraju) ===
        print(f"Generowanie {liczba_wydawcow} wydawców...")
        wydawcy_do_wstawienia = []
        uzyte_nazwy_wydawcow = set()
        for _ in range(liczba_wydawcow):
            nazwa = fake_en.company() + " Press"
            if nazwa not in uzyte_nazwy_wydawcow:
                uzyte_nazwy_wydawcow.add(nazwa)
                id_kraju = random.choice(list_of_kraj_ids)
                srednia_retrakcji = round(random.uniform(0.001, 0.05), 3)
                wydawcy_do_wstawienia.append((nazwa, id_kraju, srednia_retrakcji))

        sql_wydawca = "INSERT INTO Wydawca (nazwa, id_kraju, srednia_retrakcji) VALUES (%s, %s, %s)"
        cursor.executemany(sql_wydawca, wydawcy_do_wstawienia)
        print(f"Wstawiono {len(wydawcy_do_wstawienia)} wydawców.")

        # === D: Czasopismo (potrzebuje id_wydawcy) ===
        print("Pobieram nowe ID wydawców...")
        list_of_wydawca_ids = _pobierz_wszystkie_id(cursor, "Wydawca", "id_wydawcy")
        if not list_of_wydawca_ids:
            print("BŁĄD: Nie można pobrać ID wydawców.")
            return False

        print(f"Generowanie {liczba_czasopism} czasopism...")
        czasopisma_do_wstawienia = []
        uzyte_tytuly_czasopism = set()
        for _ in range(liczba_czasopism):
            tytul = f"Journal of {fake_en.word().capitalize()} {fake_en.word().capitalize()}"
            if tytul not in uzyte_tytuly_czasopism:
                uzyte_tytuly_czasopism.add(tytul)
                impact_factor = round(random.uniform(0.5, 12.0), 3)
                czy_otwarty_dostep = random.choice([True, False])
                id_wydawcy = random.choice(list_of_wydawca_ids)
                czasopisma_do_wstawienia.append((tytul, impact_factor, czy_otwarty_dostep, id_wydawcy))
        
        sql_czasopismo = "INSERT INTO Czasopismo (tytul, impact_factor, czy_otwarty_dostep, id_wydawcy) VALUES (%s, %s, %s, %s)"
        cursor.executemany(sql_czasopismo, czasopisma_do_wstawienia)
        print(f"Wstawiono {len(czasopisma_do_wstawienia)} czasopism.")

        # === E: Czasopismo_Punkty_Roczne (NOWA TABELA) ===
        print("Pobieram nowe ID czasopism...")
        list_of_czasopismo_ids = _pobierz_wszystkie_id(cursor, "Czasopismo", "id_czasopisma")
        if not list_of_czasopismo_ids:
            print("BŁĄD: Nie można pobrać ID czasopism.")
            return False
        
        print("Generowanie punktów rocznych dla czasopism (2010-2024)...")
        punkty_roczne_batch = []
        lata = range(2010, 2025)
        mozliwe_punkty = [20, 40, 70, 100, 140, 200]
        
        for id_czasopisma in list_of_czasopismo_ids:
            for rok in lata:
                punkty = random.choice(mozliwe_punkty)
                punkty_roczne_batch.append((id_czasopisma, rok, punkty))
        
        sql_punkty_roczne = "INSERT INTO Czasopismo_Punkty_Roczne (id_czasopisma, rok, punkty_mein) VALUES (%s, %s, %s)"
        cursor.executemany(sql_punkty_roczne, punkty_roczne_batch)
        print(f"Wstawiono {len(punkty_roczne_batch)} rekordów punktacji rocznej.")

        # === F: Afiliacja (potrzebuje id_miasta) ===
        print(f"Generowanie {liczba_afiliacji} afiliacji...")
        afiliacje_do_wstawienia = []
        uzyte_nazwy_afiliacji = set()
        for _ in range(liczba_afiliacji):
            nazwa = f"{fake_en.city()} University"
            if random.random() > 0.5:
                 nazwa = f"Institute of {fake_en.word().capitalize()} Research"
            
            if nazwa not in uzyte_nazwy_afiliacji:
                uzyte_nazwy_afiliacji.add(nazwa)
                id_miasta = random.choice(list_of_miasta_ids)
                afiliacje_do_wstawienia.append((nazwa, id_miasta))

        sql_afiliacja = "INSERT INTO Afiliacja (nazwa, id_miasta) VALUES (%s, %s)"
        cursor.executemany(sql_afiliacja, afiliacje_do_wstawienia)
        print(f"Wstawiono {len(afiliacje_do_wstawienia)} afiliacji.")
        
        print("Zakończono: Encje podstawowe.")
        return True

    except Exception as e:
        print(f"WYSTĄPIŁ BŁĄD w generuj_podstawowe_encje: {e}")
        db.rollback()
        return False

# === MODUŁ 3: AUTORZY I FINANSOWANIE ===

def generuj_autorow_i_finansowanie(db, cursor, fake: Faker, fake_en: Faker,
                                    liczba_autorow, liczba_zrodel):
    """
    Generuje dane dla: Autor, ZrodloFinansowania, Autor_Dyscyplina.
    """
    try:
        # === A: Pobranie kluczy obcych ===
        print("Pobieram istniejące ID (Kraje, Typy Finansowania, Dyscypliny)...")
        list_of_kraj_ids = _pobierz_wszystkie_id(cursor, "Kraj", "id_kraju")
        list_of_typ_ids = _pobierz_wszystkie_id(cursor, "TypFinansowania_Slownik", "id_typu")
        list_of_dyscyplina_ids = _pobierz_wszystkie_id(cursor, "Dyscypliny", "id_dyscypliny")

        if not list_of_kraj_ids:
            print("BŁĄD: Tabela Kraj jest pusta.")
            return False
        if not list_of_typ_ids:
            print("BŁĄD: Tabela TypFinansowania_Slownik jest pusta.")
            return False
        if not list_of_dyscyplina_ids:
            print("BŁĄD: Tabela Dyscypliny jest pusta.")
            return False

        # === B: Autor ===
        print(f"Generowanie {liczba_autorow} autorów...")
        autorzy_do_wstawienia = []
        uzyte_orcidy = set()
        
        for _ in tqdm(range(liczba_autorow), desc="Generowanie Autorów"):
            imie = fake.first_name()
            nazwisko = fake.last_name()
            orcid = None
            
            if random.random() < 0.7:
                while True:
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

        # === C: Autor_Dyscyplina (NOWA TABELA) ===
        print("Pobieram nowe ID autorów...")
        list_of_autor_ids = _pobierz_wszystkie_id(cursor, "Autor", "id_autora")
        if not list_of_autor_ids:
            print("BŁĄD: Nie można pobrać ID autorów.")
            return False

        print("Przypisywanie dyscyplin do autorów...")
        autor_dyscyplina_batch = []
        for id_autora in list_of_autor_ids:
            num_dyscyplin = random.randint(1, 3)
            dyscypliny_dla_autora = random.sample(list_of_dyscyplina_ids, num_dyscyplin)
            for id_dyscypliny in dyscypliny_dla_autora:
                autor_dyscyplina_batch.append((id_autora, id_dyscypliny))
        
        sql_autor_dysc = "INSERT INTO Autor_Dyscyplina (id_autora, id_dyscypliny) VALUES (%s, %s)"
        cursor.executemany(sql_autor_dysc, autor_dyscyplina_batch)
        print(f"Wstawiono {len(autor_dyscyplina_batch)} powiązań autor-dyscyplina.")

        # === D: ZrodloFinansowania ===
        print(f"Generowanie {liczba_zrodel} źródeł finansowania...")
        zrodla_do_wstawienia = []
        uzyte_nazwy_zrodel = set()
        
        for _ in range(liczba_zrodel):
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
                id_typu = random.choice(list_of_typ_ids)
                id_kraju = random.choice(list_of_kraj_ids)
                zrodla_do_wstawienia.append((nazwa, id_typu, id_kraju))

        sql_zrodlo = "INSERT INTO ZrodloFinansowania (nazwa, id_typu, id_kraju) VALUES (%s, %s, %s)"
        cursor.executemany(sql_zrodlo, zrodla_do_wstawienia)
        print(f"Wstawiono {len(zrodla_do_wstawienia)} źródeł finansowania.")
        
        print("Zakończono: Autorzy i Finansowanie.")
        return True

    except Exception as e:
        print(f"WYSTĄPIŁ BŁĄD w generuj_autorow_i_finansowanie: {e}")
        db.rollback()
        return False

# === MODUŁ 4: ARTYKUŁY I WSZYSTKIE POWIĄZANIA ===

def generuj_artykuly_i_powiazania(db, cursor, fake: Faker, fake_en: Faker,
                                   liczba_artykulow):
    """
    Główny skrypt generujący Artykuły i wszystkie powiązania m:n.
    """
    try:
        # === FAZA 0: Pobranie wszystkich niezbędnych kluczy obcych ===
        print("Pobieram pule kluczy obcych z bazy danych...")
        
        list_of_czasopismo_ids = _pobierz_wszystkie_id(cursor, "Czasopismo", "id_czasopisma")
        list_of_autor_ids = _pobierz_wszystkie_id(cursor, "Autor", "id_autora")
        list_of_zrodlo_ids = _pobierz_wszystkie_id(cursor, "ZrodloFinansowania", "id_zrodla")
        list_of_dyscyplina_ids = _pobierz_wszystkie_id(cursor, "Dyscypliny", "id_dyscypliny")
        list_of_afiliacja_ids = _pobierz_wszystkie_id(cursor, "Afiliacja", "id_afiliacji")
        
        if not all([list_of_czasopismo_ids, list_of_autor_ids, list_of_dyscyplina_ids, list_of_afiliacja_ids]):
            print("BŁĄD: Jedna z tabel (Czasopismo, Autor, Dyscypliny, Afiliacja) jest pusta.")
            return False

        # Pobranie słowników decyzji i rekomendacji
        decyzja_ids = _pobierz_id_slownika(cursor, "Decyzja_Slownik", "nazwa_decyzji", "id_decyzji")
        rekomendacja_ids = _pobierz_id_slownika(cursor, "Rekomendacja_Slownik", "nazwa_rekomendacji", "id_rekomendacji")

        if not all([decyzja_ids, rekomendacja_ids]):
            print("BŁĄD: Tabele słownikowe (Decyzja_Slownik, Rekomendacja_Slownik) są puste.")
            return False
            
        # NOWOŚĆ: Pobranie mapy punktów do pamięci dla szybkiego dostępu
        print("Pobieram mapę punktacji (Czasopismo, Rok) -> Punkty...")
        cursor.execute("SELECT id_czasopisma, rok, punkty_mein FROM Czasopismo_Punkty_Roczne")
        punkty_map = {(r[0], r[1]): r[2] for r in cursor.fetchall()}
        if not punkty_map:
            print("BŁĄD: Mapa punktacji (Czasopismo_Punkty_Roczne) jest pusta.")
            return False

        print("Pobrano pule ID. Rozpoczynam generowanie artykułów...")

        # Listy do przechowywania danych do wstawienia wsadowego (batch insert)
        art_autor_afiliacja_batch = []
        art_dyscyplina_batch = []
        art_zrodla_batch = []
        recenzja_batch = []
        
        all_generated_articles = [] # Przechowuje {'id': id_artykulu, 'rok': rok}
        uzyte_doi = set()

        # SQL'e
        sql_artykul = """
            INSERT INTO Artykul (tytul, doi, rok_publikacji, wspolczynnik_rzetelnosci, data_ostatniej_aktualizacji, id_czasopisma)
            VALUES (%s, %s, %s, %s, %s, %s)
        """
        sql_art_autor = """
            INSERT INTO Artykul_Autor (id_artykulu, id_autora, kolejnosc_autora)
            VALUES (%s, %s, %s)
        """
        # NOWY SQL: Dodane id_redaktora_prowadzacego
        sql_runda = """
            INSERT INTO RundaRecenzyjna (id_artykulu, numer_rundy, data_rozpoczecia, data_zakonczenia, id_decyzji, id_redaktora_prowadzacego)
            VALUES (%s, %s, %s, %s, %s, %s)
        """
        
        # === FAZA 1: Pętla generująca artykuły i powiązania ===
        
        for i in tqdm(range(liczba_artykulow), desc="Generowanie Artykułów"):
            
            # --- 1. Wstaw Artykul ---
            tytul = fake_en.sentence(nb_words=10).replace('.', '') + " in " + fake_en.word().capitalize()
            
            # Zapewnienie unikalnego DOI
            while True:
                doi = f"10.1000/{random.randint(1000, 9999)}.{random.randint(10000, 99999)}"
                if doi not in uzyte_doi:
                    uzyte_doi.add(doi)
                    break
                    
            rok_pub = random.randint(2010, 2024)
            id_czasopisma = random.choice(list_of_czasopismo_ids)
            
            # NOWA LOGIKA: Pobieranie punktów z mapy, a nie losowanie
            punkty_mein = punkty_map.get((id_czasopisma, rok_pub), 0) # 0 jeśli brak wpisu
            
            wsp_rzetelnosci = round(random.uniform(0.85, 1.0), 3)
            data_akt = _generuj_date(rok_pub, 2024)
            
            val_artykul = (tytul, doi, rok_pub, wsp_rzetelnosci, data_akt, id_czasopisma)
            cursor.execute(sql_artykul, val_artykul)
            id_artykulu = cursor.lastrowid
            all_generated_articles.append({'id': id_artykulu, 'rok': rok_pub})

            # --- 2. Wstaw Artykul_Autor i Artykul_Autor_Afiliacja ---
            num_authors = random.randint(1, 6)
            autorzy_dla_tego_artykulu = random.sample(list_of_autor_ids, num_authors)
            
            for k, id_autora in enumerate(autorzy_dla_tego_artykulu):
                val_art_autor = (id_artykulu, id_autora, k + 1)
                cursor.execute(sql_art_autor, val_art_autor)
                id_artykul_autor = cursor.lastrowid
                
                num_afiliacji = random.randint(1, 2)
                afiliacje_dla_autora = random.sample(list_of_afiliacja_ids, num_afiliacji)
                for id_afiliacji in afiliacje_dla_autora:
                    art_autor_afiliacja_batch.append((id_artykul_autor, id_afiliacji))

            # --- 3. Wstaw Artykul_Dyscyplina (do batcha) ---
            num_dyscyplin = random.randint(1, 3)
            dyscypliny_dla_artykulu = random.sample(list_of_dyscyplina_ids, num_dyscyplin)
            for id_dyscypliny in dyscypliny_dla_artykulu:
                art_dyscyplina_batch.append((id_artykulu, id_dyscypliny))

            # --- 4. Wstaw Artykul_ZrodloFinansowania (do batcha) ---
            if random.random() < SZANSA_NA_FINANSOWANIE and list_of_zrodlo_ids:
                num_zrodel = random.randint(1, 2)
                zrodla_dla_artykulu = random.sample(list_of_zrodlo_ids, num_zrodel)
                for id_zrodla in zrodla_dla_artykulu:
                    art_zrodla_batch.append((id_artykulu, id_zrodla))

            # --- 5. Symulacja Recenzji ---
            
            # NOWA LOGIKA: Wybór redaktora prowadzącego
            # Redaktor nie może być autorem
            possible_editors = [a_id for a_id in list_of_autor_ids if a_id not in autorzy_dla_tego_artykulu]
            if not possible_editors: # Skrajny przypadek, gdy wszyscy autorzy są autorami
                possible_editors = list_of_autor_ids 
                
            id_redaktora_prow_r1 = random.choice(possible_editors)
            
            # --- RUNDA 1 ---
            data_r1_start = _generuj_date(rok_pub - 1, rok_pub)
            data_r1_end = data_r1_start + datetime.timedelta(days=random.randint(30, 90))
            decyzja1_id = random.choice([
                decyzja_ids['Drobne poprawki'], 
                decyzja_ids['Duże poprawki'], 
                decyzja_ids['Odrzucony']
            ])
            
            val_runda1 = (id_artykulu, 1, data_r1_start, data_r1_end, decyzja1_id, id_redaktora_prow_r1)
            cursor.execute(sql_runda, val_runda1)
            id_rundy1 = cursor.lastrowid
            
            # Wstaw Recenzje dla Rundy 1 (do batcha)
            recenzenci1 = set()
            for _ in range(random.randint(2, 3)):
                id_recenzenta = random.choice(list_of_autor_ids)
                # NOWA LOGIKA: Recenzent nie może być autorem, redaktorem ani recenzować dwa razy
                while id_recenzenta in autorzy_dla_tego_artykulu or \
                      id_recenzenta == id_redaktora_prow_r1 or \
                      id_recenzenta in recenzenci1:
                    id_recenzenta = random.choice(list_of_autor_ids)
                recenzenci1.add(id_recenzenta)
                
                if decyzja1_id == decyzja_ids['Odrzucony']: rek_id = rekomendacja_ids['Odrzucenie']
                elif decyzja1_id == decyzja_ids['Duże poprawki']: rek_id = rekomendacja_ids['Duże poprawki']
                else: rek_id = rekomendacja_ids['Drobne poprawki']
                
                tresc = fake_en.paragraph(nb_sentences=4)
                data_otrz = data_r1_start + datetime.timedelta(days=random.randint(10, 29))
                recenzja_batch.append((id_rundy1, id_recenzenta, rek_id, tresc, data_otrz))

            # --- RUNDA 2 (możliwa) ---
            if decyzja1_id == decyzja_ids['Duże poprawki'] and random.random() < SZANSA_NA_DRUGA_RUNDE:
                id_redaktora_prow_r2 = random.choice(possible_editors) # Może być ten sam lub inny
                
                data_r2_start = data_r1_end + datetime.timedelta(days=random.randint(10, 30))
                data_r2_end = data_r2_start + datetime.timedelta(days=random.randint(20, 60))
                decyzja2_id = random.choice([
                    decyzja_ids['Zaakceptowany'], 
                    decyzja_ids['Odrzucony']
                ])
                
                val_runda2 = (id_artykulu, 2, data_r2_start, data_r2_end, decyzja2_id, id_redaktora_prow_r2)
                cursor.execute(sql_runda, val_runda2)
                id_rundy2 = cursor.lastrowid
                
                recenzenci2 = set()
                for _ in range(2):
                    id_recenzenta = random.choice(list_of_autor_ids)
                    # Recenzent R2 nie może być autorem, redaktoremR2 ani recenzować R2 dwa razy
                    while id_recenzenta in autorzy_dla_tego_artykulu or \
                          id_recenzenta == id_redaktora_prow_r2 or \
                          id_recenzenta in recenzenci2:
                        id_recenzenta = random.choice(list_of_autor_ids)
                    recenzenci2.add(id_recenzenta)

                    if decyzja2_id == decyzja_ids['Zaakceptowany']: rek_id = rekomendacja_ids['Akceptacja']
                    else: rek_id = rekomendacja_ids['Odrzucenie']
                    
                    tresc = fake_en.paragraph(nb_sentences=2)
                    data_otrz = data_r2_start + datetime.timedelta(days=random.randint(10, 19))
                    recenzja_batch.append((id_rundy2, id_recenzenta, rek_id, tresc, data_otrz))

        print(f"Zakończono generowanie {liczba_artykulow} artykułów.")
        
        # === FAZA 2: Wstawianie wsadowe (Batch Insert) powiązań m:n ===
        
        print(f"Wstawianie powiązań (Afiliacje: {len(art_autor_afiliacja_batch)}, Dyscypliny: {len(art_dyscyplina_batch)})...")
        
        sql_art_aut_afil = "INSERT INTO Artykul_Autor_Afiliacja (id_artykul_autor, id_afiliacji) VALUES (%s, %s)"
        cursor.executemany(sql_art_aut_afil, art_autor_afiliacja_batch)
        
        sql_art_dysc = "INSERT INTO Artykul_Dyscyplina (id_artykulu, id_dyscypliny) VALUES (%s, %s)"
        cursor.executemany(sql_art_dysc, art_dyscyplina_batch)
        
        sql_art_zrodla = "INSERT INTO Artykul_ZrodloFinansowania (id_artykulu, id_zrodla) VALUES (%s, %s)"
        cursor.executemany(sql_art_zrodla, art_zrodla_batch)
        
        sql_recenzja = "INSERT INTO Recenzja (id_rundy, id_autora_recenzenta, id_rekomendacji, tresc_recenzji, data_otrzymania) VALUES (%s, %s, %s, %s, %s)"
        cursor.executemany(sql_recenzja, recenzja_batch)

        print(f"Wstawiono powiązania i {len(recenzja_batch)} recenzji.")

        # === FAZA 3: Generowanie Cytowań ===
        
        print("Generowanie sieci cytowań...")
        cytowania_batch = []
        unikalne_cytowania_set = set()
        sql_cytowanie = "INSERT INTO Cytowanie (id_cytujacego, id_cytowanego, data_zdarzenia) VALUES (%s, %s, %s)"

        for artykul_cytujacy in tqdm(all_generated_articles, desc="Generowanie Cytowań"):
            id_cytujacego = artykul_cytujacy['id']
            rok_cytujacego = artykul_cytujacy['rok']
            
            liczba_cytowan = random.randint(0, 20)
            if liczba_cytowan == 0:
                continue
                
            cytowane_artykuly = random.sample(all_generated_articles, liczba_cytowan)
            
            for artykul_cytowany in cytowane_artykuly:
                id_cytowanego = artykul_cytowany['id']
                rok_cytowanego = artykul_cytowany['rok']
                
                if id_cytujacego != id_cytowanego and \
                   rok_cytujacego >= rok_cytowanego and \
                   (id_cytujacego, id_cytowanego) not in unikalne_cytowania_set:
                    
                    unikalne_cytowania_set.add((id_cytujacego, id_cytowanego))
                    data_cyt = _generuj_date(rok_cytujacego, 2024)
                    cytowania_batch.append((id_cytujacego, id_cytowanego, data_cyt))

        if cytowania_batch:
            cursor.executemany(sql_cytowanie, cytowania_batch)
            print(f"Wstawiono {len(cytowania_batch)} cytowań.")
        else:
            print("Nie wstawiono żadnych cytowań.")
            
        print("Zakończono: Artykuły i Powiązania.")
        return True

    except Exception as e:
        print(f"WYSTĄPIŁ BŁĄD w generuj_artykuly_i_powiazania: {e}")
        db.rollback()
        return False

# === GŁÓWNY BLOK WYKONAWCZY ===

if __name__ == "__main__":
    
    # --- ZMIEŃ TE WARTOŚCI ---
    DB_HOST = "localhost"
    DB_USER = "rpc_admin"      # Updated to match setup script
    DB_PASSWORD = "Silnehaslo123." # Updated to match setup script (dot at end)
    DB_NAME = "rpc"            # Updated to match setup script
    # ---------------------------

    db = None
    cursor = None
    try:
        # Nawiązywanie połączenia
        db = mysql.connector.connect(
            host=DB_HOST,
            user=DB_USER,
            password=DB_PASSWORD,
            database=DB_NAME
        )
        if db.is_connected():
            print(f"Połączono z bazą danych '{DB_NAME}' na '{DB_HOST}'!")
        else:
            print("Nie udało się połączyć z bazą danych.")
            sys.exit(1)

        cursor = db.cursor()
        
        # Ustawienie wysokiego limitu dla GROUP_CONCAT, jeśli zajdzie potrzeba
        # (chociaż ten skrypt tego nie używa, to dobra praktyka)
        cursor.execute("SET SESSION group_concat_max_len = 1000000;")
        
        # Inicjalizacja Fakerów
        fake = Faker('pl_PL')
        fake_en = Faker('en_US')

        # === SEKWENCJA URUCHOMIENIOWA ===
        # Kolejność jest kluczowa ze względu na klucze obce!
        
        print("\n--- KROK 1/4: Generowanie Krajów i Miast ---")
        if not generuj_kraje_miasta(db, cursor, fake, LICZBA_KRAJOW):
            raise Exception("Krok 1 nie powiódł się. Przerywam.")

        print("\n--- KROK 2/4: Generowanie Encji Podstawowych (Wydawcy, Czasopisma, Punkty, Afiliacje) ---")
        if not generuj_podstawowe_encje(db, cursor, fake, fake_en, LICZBA_WYDAWCOW, LICZBA_CZASOPISM, LICZBA_AFILIACJI):
            raise Exception("Krok 2 nie powiódł się. Przerywam.")
            
        print("\n--- KROK 3/4: Generowanie Autorów, Źródeł Finansowania i Specjalizacji Autorów ---")
        if not generuj_autorow_i_finansowanie(db, cursor, fake, fake_en, LICZBA_AUTOROW, LICZBA_ZRODEL):
            raise Exception("Krok 3 nie powiódł się. Przerywam.")

        print("\n--- KROK 4/4: Generowanie Artykułów i wszystkich Powiązań (Recenzje, Cytowania, etc.) ---")
        if not generuj_artykuly_i_powiazania(db, cursor, fake, fake_en, LICZBA_ARTYKULOW):
            raise Exception("Krok 4 nie powiódł się. Przerywam.")

        # === FINALIZACJA ===
        print("\n=======================================================")
        print("Operacje zakończone sukcesem. Zatwierdzam zmiany (COMMIT)...")
        db.commit()
        print("ZMIANY ZOSTAŁY ZATWIERDZONE.")
        print("=======================================================")

    except MySQLError as err:
        print(f"\nBŁĄD BAZY DANYCH: {err}")
        print("Wycofuję zmiany (ROLLBACK)...")
        if db:
            db.rollback()
        print("Zmiany wycofane.")
    except Exception as e:
        print(f"\nWYSTĄPIŁ KRYTYCZNY BŁĄD: {e}")
        print("Wycofuję zmiany (ROLLBACK)...")
        if db:
            db.rollback()
        print("Zmiany wycofane.")
    finally:
        # Zamykanie połączenia
        if cursor:
            cursor.close()
        if db and db.is_connected():
            db.close()
            print("\nRozłączono z bazą danych.")