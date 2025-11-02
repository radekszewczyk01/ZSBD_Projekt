import mysql.connector
from faker import Faker
import random
import sys
#
# żeby na pewno się nie pomylić od razu po wykonaniu zakomentowywałem dany import
#
# from python_subscripts.s01_kraje_miasta import generuj_kraje_miasta
# from python_subscripts.s02_podstawowe_encje import generuj_podstawowe_encje
# from python_subscripts.s03_autorzy_finansowanie import generuj_autorow_i_finansowanie
# from python_subscripts.s04_artykuly_powiazania import generuj_artykuly_i_powiazania

try:
    db = mysql.connector.connect(
        host="localhost",
        user="rpc_admin",
        password="Silnehaslo123.",
        database="rpc"
    )
    print("Połączono z bazą danych!")
except mysql.connector.Error as err:
    print(f"Błąd połączenia: {err}")
    exit()


cursor = db.cursor()

fake = Faker('pl_PL')
fake_en = Faker('en_US')

try:
    print("\n--- KROK n... ---")
    # sukces1 = generuj_kraje_miasta(db, cursor, fake)
    # sukces2 = generuj_podstawowe_encje(db, cursor, fake, fake_en)
    # sukces3 = generuj_autorow_i_finansowanie(db, cursor, fake, fake_en)
    # sukces4 = generuj_artykuly_i_powiazania(db, cursor, fake, fake_en)
    if not sukces4:
        raise Exception("Krok 1 nie powiódł się. Przerywam.")

    print("\nOperacje zakończone sukcesem. Zatwierdzam zmiany (COMMIT)...")
    db.commit()

except mysql.connector.Error as err:
    print(f"Błąd zapytania: {err}")
    db.rollback()

finally:
    cursor.close()
    db.close()
    print("\nRozłączono z bazą danych.")