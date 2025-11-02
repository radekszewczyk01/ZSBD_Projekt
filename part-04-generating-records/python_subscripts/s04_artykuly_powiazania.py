# Zawartość pliku: python_subscripts/s04_artykuly_powiazania.py

import random
import datetime
from faker import Faker
from mysql.connector import Error as MySQLError

# Opcjonalny import paska postępu. Jeśli nie masz tqdm,
# zamień 'from tqdm import tqdm' na 'tqdm = lambda x, **kwargs: x'
try:
    from tqdm import tqdm
except ImportError:
    print("Biblioteka 'tqdm' nie znaleziona. Paski postępu będą wyłączone.")
    print("Zainstaluj ją (pip install tqdm) dla lepszego doświadczenia.")
    # Tworzymy fałszywą funkcję tqdm, która po prostu zwraca iterator
    tqdm = lambda x, **kwargs: x

# === GŁÓWNA KONFIGURACJA ===
LICZBA_ARTYKULOW = 5000  # Zmień tę wartość, jeśli chcesz więcej/mniej
SZAJSA_NA_FINANSOWANIE = 0.4  # 40% artykułów będzie miało źródło finansowania
SZANSA_NA_DRUGA_RUNDE = 0.3  # 30% artykułów z "Dużymi poprawkami" pójdzie do 2. rundy


# === FUNKCJE POMOCNICZE ===

def _pobierz_wszystkie_id(cursor, tabela, kolumna_id):
    """Pomocnik: Pobiera listę wszystkich ID z danej tabeli."""
    try:
        cursor.execute(f"SELECT {kolumna_id} FROM {tabela}")
        wyniki = cursor.fetchall()
        return [item[0] for item in wyniki]
    except MySQLError as e:
        print(f"Błąd podczas pobierania ID z tabeli {tabela}: {e}")
        return []

def _pobierz_id_slownika(cursor, tabela, kolumna_nazwa, kolumna_id):
    """Pomocnik: Pobiera słownik mapujący Nazwa -> ID."""
    try:
        cursor.execute(f"SELECT {kolumna_nazwa}, {kolumna_id} FROM {tabela}")
        wyniki = cursor.fetchall()
        # Tworzy słownik np. {'Zaakceptowany': 1, 'Odrzucony': 4}
        return {nazwa: id_val for nazwa, id_val in wyniki}
    except MySQLError as e:
        print(f"Błąd podczas pobierania słownika {tabela}: {e}")
        return {}

def _generuj_date(start_year=2000, end_year=2024):
    """Generuje losową datę."""
    year = random.randint(start_year, end_year)
    month = random.randint(1, 12)
    day = random.randint(1, 28) # Uproszczenie dla bezpieczeństwa
    return datetime.date(year, month, day)


# === GŁÓWNA FUNKCJA ===

def generuj_artykuly_i_powiazania(db, cursor, fake: Faker, fake_en: Faker):
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
        
        # Sprawdzenie, czy kluczowe tabele nie są puste
        if not all([list_of_czasopismo_ids, list_of_autor_ids, list_of_dyscyplina_ids, list_of_afiliacja_ids]):
            print("BŁĄD: Jedna z tabel (Czasopismo, Autor, Dyscypliny, Afiliacja) jest pusta.")
            return False

        # Pobranie słowników decyzji i rekomendacji
        decyzja_ids = _pobierz_id_slownika(cursor, "Decyzja_Slownik", "nazwa_decyzji", "id_decyzji")
        rekomendacja_ids = _pobierz_id_slownika(cursor, "Rekomendacja_Slownik", "nazwa_rekomendacji", "id_rekomendacji")

        if not all([decyzja_ids, rekomendacja_ids]):
            print("BŁĄD: Tabele słownikowe (Decyzja_Slownik, Rekomendacja_Slownik) są puste.")
            return False

        print("Pobrano pule ID. Rozpoczynam generowanie artykułów...")

        # Listy do przechowywania danych do wstawienia wsadowego (batch insert)
        art_autor_afiliacja_batch = []
        art_dyscyplina_batch = []
        art_zrodla_batch = []
        recenzja_batch = []
        
        # Lista do przechowywania ID i lat artykułów (dla cytowań)
        all_generated_articles = [] # Przechowuje {'id': id_artykulu, 'rok': rok}

        # SQL'e
        sql_artykul = """
            INSERT INTO Artykul (tytul, doi, rok_publikacji, punkty_mein, wspolczynnik_rzetelnosci, data_ostatniej_aktualizacji, id_czasopisma)
            VALUES (%s, %s, %s, %s, %s, %s, %s)
        """
        sql_art_autor = """
            INSERT INTO Artykul_Autor (id_artykulu, id_autora, kolejnosc_autora)
            VALUES (%s, %s, %s)
        """
        sql_runda = """
            INSERT INTO RundaRecenzyjna (id_artykulu, numer_rundy, data_rozpoczecia, data_zakonczenia, id_decyzji)
            VALUES (%s, %s, %s, %s, %s)
        """
        
        # === FAZA 1: Pętla generująca artykuły i powiązania ===
        # Ta pętla musi wstawiać rekordy 1-by-1, aby dostać 'lastrowid'
        
        for i in tqdm(range(LICZBA_ARTYKULOW), desc="Generowanie Artykułów"):
            
            # --- 1. Wstaw Artykul ---
            tytul = fake_en.sentence(nb_words=10).replace('.', '') + " in " + fake_en.word().capitalize()
            doi = f"10.1000/{random.randint(1000, 9999)}.{random.randint(10000, 99999)}"
            rok_pub = random.randint(2010, 2024)
            punkty_mein = random.choice([20, 40, 70, 100, 140, 200])
            wsp_rzetelnosci = round(random.uniform(0.85, 1.0), 3)
            data_akt = _generuj_date(rok_pub, 2024)
            id_czasopisma = random.choice(list_of_czasopismo_ids)
            
            val_artykul = (tytul, doi, rok_pub, punkty_mein, wsp_rzetelnosci, data_akt, id_czasopisma)
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
                
                # Dodaj afiliacje do kolejki (batch)
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
            if random.random() < SZAJSA_NA_FINANSOWANIE and list_of_zrodlo_ids:
                num_zrodel = random.randint(1, 2)
                zrodla_dla_artykulu = random.sample(list_of_zrodlo_ids, num_zrodel)
                for id_zrodla in zrodla_dla_artykulu:
                    art_zrodla_batch.append((id_artykulu, id_zrodla))

            # --- 5. Symulacja Recenzji ---
            
            # --- RUNDA 1 ---
            data_r1_start = _generuj_date(rok_pub - 1, rok_pub)
            data_r1_end = data_r1_start + datetime.timedelta(days=random.randint(30, 90))
            # Losujemy decyzję Rundy 1 (Drobne, Duże, Odrzucony)
            decyzja1_id = random.choice([
                decyzja_ids['Drobne poprawki'], 
                decyzja_ids['Duże poprawki'], 
                decyzja_ids['Odrzucony']
            ])
            
            val_runda1 = (id_artykulu, 1, data_r1_start, data_r1_end, decyzja1_id)
            cursor.execute(sql_runda, val_runda1)
            id_rundy1 = cursor.lastrowid
            
            # Wstaw Recenzje dla Rundy 1 (do batcha)
            recenzenci1 = set() # By uniknąć dodania tej samej osoby
            for _ in range(random.randint(2, 3)): # 2-3 recenzentów
                id_recenzenta = random.choice(list_of_autor_ids)
                # Recenzent nie może być autorem I nie może recenzować dwa razy tej samej rundy
                while id_recenzenta in autorzy_dla_tego_artykulu or id_recenzenta in recenzenci1:
                    id_recenzenta = random.choice(list_of_autor_ids)
                recenzenci1.add(id_recenzenta)
                
                # Rekomendacja musi być spójna z decyzją
                if decyzja1_id == decyzja_ids['Odrzucony']:
                    rek_id = rekomendacja_ids['Odrzucenie']
                elif decyzja1_id == decyzja_ids['Duże poprawki']:
                    rek_id = rekomendacja_ids['Duże poprawki']
                else: # Drobne poprawki
                    rek_id = rekomendacja_ids['Drobne poprawki']
                
                tresc = fake_en.paragraph(nb_sentences=4)
                data_otrz = data_r1_start + datetime.timedelta(days=random.randint(10, 29))
                recenzja_batch.append((id_rundy1, id_recenzenta, rek_id, tresc, data_otrz))

            # --- RUNDA 2 (możliwa tylko jeśli R1 to "Duże poprawki") ---
            if decyzja1_id == decyzja_ids['Duże poprawki'] and random.random() < SZANSA_NA_DRUGA_RUNDE:
                data_r2_start = data_r1_end + datetime.timedelta(days=random.randint(10, 30))
                data_r2_end = data_r2_start + datetime.timedelta(days=random.randint(20, 60))
                # Decyzja finalna: Zaakceptowany lub Odrzucony
                decyzja2_id = random.choice([
                    decyzja_ids['Zaakceptowany'], 
                    decyzja_ids['Odrzucony']
                ])
                
                val_runda2 = (id_artykulu, 2, data_r2_start, data_r2_end, decyzja2_id)
                cursor.execute(sql_runda, val_runda2)
                id_rundy2 = cursor.lastrowid
                
                # Wstaw Recenzje dla Rundy 2 (do batcha)
                recenzenci2 = set()
                for _ in range(2): # Zwykle mniej recenzentów w 2. rundzie
                    id_recenzenta = random.choice(list(recenzenci1)) # Często ci sami recenzenci
                    if id_recenzenta in recenzenci2: # Unikamy duplikatu
                         id_recenzenta = random.choice(list_of_autor_ids)
                         while id_recenzenta in autorzy_dla_tego_artykulu or id_recenzenta in recenzenci1 or id_recenzenta in recenzenci2:
                            id_recenzenta = random.choice(list_of_autor_ids)
                    
                    recenzenci2.add(id_recenzenta)

                    if decyzja2_id == decyzja_ids['Zaakceptowany']:
                        rek_id = rekomendacja_ids['Akceptacja']
                    else:
                        rek_id = rekomendacja_ids['Odrzucenie']
                    
                    tresc = fake_en.paragraph(nb_sentences=2) # Krótsza recenzja
                    data_otrz = data_r2_start + datetime.timedelta(days=random.randint(10, 19))
                    recenzja_batch.append((id_rundy2, id_recenzenta, rek_id, tresc, data_otrz))

        print(f"Zakończono generowanie {LICZBA_ARTYKULOW} artykułów.")
        
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
        unikalne_cytowania_set = set() # Do obsługi UNIQUE(id_cytujacego, id_cytowanego)
        
        sql_cytowanie = "INSERT INTO Cytowanie (id_cytujacego, id_cytowanego, data_zdarzenia) VALUES (%s, %s, %s)"

        # Iterujemy po wszystkich artykułach, które stworzyliśmy
        for artykul_cytujacy in tqdm(all_generated_articles, desc="Generowanie Cytowań"):
            id_cytujacego = artykul_cytujacy['id']
            rok_cytujacego = artykul_cytujacy['rok']
            
            # Każdy artykuł cytuje od 0 do 20 innych artykułów
            liczba_cytowan = random.randint(0, 20)
            
            # Wybieramy losowe artykuły do zacytowania
            cytowane_artykuly = random.sample(all_generated_articles, liczba_cytowan)
            
            for artykul_cytowany in cytowane_artykuly:
                id_cytowanego = artykul_cytowany['id']
                rok_cytowanego = artykul_cytowany['rok']
                
                # --- INTELIGENTNA LOGIKA ---
                # 1. Nie można cytować samego siebie
                # 2. Nie można cytować artykułu z przyszłości
                # 3. Sprawdzamy unikalność (klucz UNIQUE)
                
                if id_cytujacego != id_cytowanego and \
                   rok_cytujacego >= rok_cytowanego and \
                   (id_cytujacego, id_cytowanego) not in unikalne_cytowania_set:
                    
                    unikalne_cytowania_set.add((id_cytujacego, id_cytowanego))
                    data_cyt = _generuj_date(rok_cytujacego, 2024) # Cytowanie następuje w roku publikacji lub później
                    cytowania_batch.append((id_cytujacego, id_cytowanego, data_cyt))

        # Wstawiamy wszystkie cytowania na raz
        if cytowania_batch:
            cursor.executemany(sql_cytowanie, cytowania_batch)
            print(f"Wstawiono {len(cytowania_batch)} cytowań.")
        else:
            print("Nie wstawiono żadnych cytowań.")
            
        print("Zakończono generowanie artykułów i wszystkich powiązań.")
        return True

    except MySQLError as e:
        print(f"WYSTĄPIŁ BŁĄD BAZY DANYCH w s04_artykuly_powiazania: {e}")
        return False
    except Exception as e:
        print(f"WYSTĄPIŁ BŁĄD OGÓLNY w s04_artykuly_powiazania: {e}")
        return False