# Zawartość pliku: python_subscripts/s01_kraje_miasta.py

from faker import Faker
import random
# Nie importujemy mysql.connector - połączenie dostaniemy z zewnątrz

def generuj_kraje_miasta(db, cursor, fake: Faker):
    """
    Generuje 100 krajów i 5-15 miast dla każdego z nich.
    Korzysta z istniejącego połączenia z bazą danych.
    """
    try:
        print("Rozpoczynam generowanie 100 krajów...")

        uzyte_nazwy_krajow = set()
        kraje_do_wstawienia = [] # (nazwa_kraju,)

        while len(kraje_do_wstawienia) < 100:
            nazwa_kraju = fake.country()
            if nazwa_kraju not in uzyte_nazwy_krajow:
                uzyte_nazwy_krajow.add(nazwa_kraju)
                kraje_do_wstawienia.append((nazwa_kraju,))

        sql_kraj = "INSERT INTO Kraj (nazwa) VALUES (%s)"
        cursor.executemany(sql_kraj, kraje_do_wstawienia)

        print(f"Wstawiono {cursor.rowcount} krajów. Pobieram ich ID...")

        pierwszy_id_kraju = cursor.lastrowid
        if pierwszy_id_kraju is None:
             # Obsługa błędu, jeśli z jakiegoś powodu lastrowid nie zadziała
             print("BŁĄD: Nie udało się pobrać ID ostatnio wstawionego kraju.")
             # W bardziej rozbudowanym skrypcie można by pobrać ID inaczej
             # Na razie przerywamy, by uniknąć dalszych błędów
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
        else:
            print("Nie wygenerowano żadnych miast.")

        # WAŻNE: commit robimy w main.py!
        # db.commit() 
        
        print(f"Zakończono generowanie krajów i miast.")
        return True # Sukces

    except Exception as e:
        print(f"WYSTĄPIŁ BŁĄD w s01_kraje_miasta: {e}")
        return False # Porażka