#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Samodzielny skrypt do generowania dużej liczby rekordów 
wyłącznie dla tabeli 'Czasopismo_Punkty_Roczne'.

Używa istniejących ID z tabeli 'Czasopismo'.
"""

import mysql.connector
from mysql.connector import Error as MySQLError
import random
import sys
import math

try:
    from tqdm import tqdm
except ImportError:
    print("Biblioteka 'tqdm' nie znaleziona. Paski postępu będą wyłączone.")
    print("Zainstaluj ją (pip install tqdm) dla lepszego doświadczenia.")
    tqdm = lambda x, **kwargs: x

# === KONFIGURACJA ===
DB_HOST = "localhost"
DB_USER = "nowy_admin"
DB_PASSWORD = "SilneHaslo123!"
DB_NAME = "rims_v2"

# Ustaw docelową liczbę rekordów do wygenerowania
DOCELOWA_LICZBA_REKORDOW = 500000

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

def generuj_punkty(db, cursor, docelowa_liczba):
    """
    Generuje rekordy dla Czasopismo_Punkty_Roczne.
    """
    try:
        # === KROK 1: Pobranie zależności ===
        print(f"Pobieram ID istniejących czasopism z tabeli 'Czasopismo'...")
        list_of_czasopismo_ids = _pobierz_wszystkie_id(cursor, "Czasopismo", "id_czasopisma")

        if not list_of_czasopismo_ids:
            print("BŁĄD: Tabela 'Czasopismo' jest pusta.")
            print("Nie można wygenerować punktów bez istniejących czasopism.")
            return False
            
        liczba_czasopism = len(list_of_czasopismo_ids)
        print(f"Znaleziono {liczba_czasopism} unikalnych czasopism.")

        # === KROK 2: Obliczenie wymaganego zakresu lat ===
        # Obliczamy, ile lat potrzebujemy, aby osiągnąć cel 500 000
        # (zawsze zaokrąglamy w górę)
        try:
            liczba_lat = math.ceil(docelowa_liczba / liczba_czasopism)
        except ZeroDivisionError:
             print("BŁĄD: Zero czasopism.")
             return False

        rok_koncowy = 2024
        rok_poczatkowy = rok_koncowy - liczba_lat + 1
        lata = range(rok_poczatkowy, rok_koncowy + 1)

        print(f"Aby wygenerować ~{docelowa_liczba} rekordów dla {liczba_czasopism} czasopism,")
        print(f"potrzebujemy {len(lata)} lat danych (Zakres: {rok_poczatkowy} - {rok_koncowy}).")

        # === KROK 3: Czyszczenie tabeli ===
        # Musimy to zrobić, aby uniknąć błędów PRIMARY KEY (id_czasopisma, rok)
        print("\nUWAGA: Czyszczę tabelę 'Czasopismo_Punkty_Roczne', aby uniknąć błędów duplikatów...")
        try:
            # Wyłączenie kluczy obcych nie jest konieczne do DELETE, 
            # ale dobra praktyka przy TRUNCATE
            cursor.execute("DELETE FROM Czasopismo_Punkty_Roczne")
            print(f"Wyczyszczono. Usunięto {cursor.rowcount} starych rekordów.")
        except MySQLError as e:
            print(f"Błąd podczas czyszczenia tabeli: {e}")
            print("Możliwe, że inne tabele mają klucz obcy do Czasopismo_Punkty_Roczne.")
            db.rollback()
            return False

        # === KROK 4: Generowanie danych ===
        mozliwe_punkty = [20, 40, 70, 100, 140, 200]
        punkty_roczne_batch = []
        
        print("Przygotowuję dane do wstawienia...")
        for id_czasopisma in tqdm(list_of_czasopismo_ids, desc="Przetwarzanie czasopism"):
            for rok in lata:
                punkty = random.choice(mozliwe_punkty)
                punkty_roczne_batch.append((id_czasopisma, rok, punkty))

        # === KROK 5: Wstawianie wsadowe ===
        print(f"\nPrzygotowano {len(punkty_roczne_batch)} rekordów. Wstawianie do bazy danych...")
        
        sql_punkty_roczne = "INSERT INTO Czasopismo_Punkty_Roczne (id_czasopisma, rok, punkty_mein) VALUES (%s, %s, %s)"
        
        # Dzielimy na mniejsze paczki, aby uniknąć problemów z pamięcią
        rozmiar_paczki = 50000
        liczba_paczek = math.ceil(len(punkty_roczne_batch) / rozmiar_paczki)
        
        for i in tqdm(range(liczba_paczek), desc="Wstawianie paczek"):
            paczka = punkty_roczne_batch[i*rozmiar_paczki : (i+1)*rozmiar_paczki]
            cursor.executemany(sql_punkty_roczne, paczka)

        print(f"Wstawiono łącznie {len(punkty_roczne_batch)} rekordów.")
        return True

    except Exception as e:
        print(f"WYSTĄPIŁ BŁĄD w generuj_punkty: {e}")
        db.rollback()
        return False

# === GŁÓWNY BLOK WYKONAWCZY ===

if __name__ == "__main__":
    
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
        if not db.is_connected():
            print("Nie udało się połączyć z bazą danych.")
            sys.exit(1)
            
        print(f"Połączono z bazą danych '{DB_NAME}' na '{DB_HOST}'!")
        cursor = db.cursor()

        # === SEKWENCJA URUCHOMIENIOWA ===
        if not generuj_punkty(db, cursor, DOCELOWA_LICZBA_REKORDOW):
            raise Exception("Generowanie punktów nie powiodło się. Przerywam.")

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