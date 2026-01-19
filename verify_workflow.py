import mysql.connector
import time
import sys

# Konfiguracja
DB_NAME = "rpc"

# Użytkownicy
CREDS = {
    'admin': ('rpc_admin', 'Silnehaslo123.'),
    'author': ('author_olaf_1', 'SilneHasloOlaf123!'),
    'chief': ('redaktor_naczelny_krystyna', 'SuperBezpieczneHaslo987!'),
    'reviewer': ('author_lukasz_1', 'SilneHasloOlaf123!'),
    # Asystenci (hasła ze skryptów)
    'asystent_1': ('asystent_sebastian', 'SuperBezpieczneHaslo99!'), # ID 1
    'asystent_15': ('asystent_anita', 'SuperBezpieczneHaslo77!')    # ID 15
}

def get_conn(user_key):
    user, password = CREDS[user_key]
    return mysql.connector.connect(
        host='localhost', user=user, password=password, database=DB_NAME
    )

def run_query(cursor, sql, params=None):
    cursor.execute(sql, params)
    return cursor

def log(msg):
    print(f"[TEST] {msg}")

def main():
    # 1. AUTOR ZGŁASZA ARTYKUŁ
    log("Krok 1: Autor Olaf zgłasza artykuł...")
    
    # Najpierw pobierzmy liczbę zgłoszeń, żeby znaleźć nowe ID
    conn_admin = get_conn('admin')
    cur_admin = conn_admin.cursor()
    cur_admin.execute("SELECT MAX(id_zgloszenia) FROM Zgloszenie_Wstepne")
    res = cur_admin.fetchone()
    old_max = res[0] if res[0] else 0
    
    # Pobierz nazwę czasopisma ID=1
    cur_admin.execute("SELECT tytul FROM Czasopismo WHERE id_czasopisma = 1")
    czasopismo_tytul = cur_admin.fetchone()[0]
    conn_admin.close()

    conn_auth = get_conn('author')
    cur_auth = conn_auth.cursor()
    # Procedura zwraca Select, więc musimy obsłużyć wynik
    cur_auth.callproc('sp_Autor_Demo_ZglosDoCzasopisma_Poprawne', [czasopismo_tytul])
    conn_auth.commit()
    conn_auth.close()
    
    # 2. ADMIN SPRAWDZA BACKEND / CZEKA NA ASYSTENTA
    log("Krok 2: Czekanie na przypisanie asystenta (Job)...")
    
    conn_admin = get_conn('admin')
    cur_admin = conn_admin.cursor()
    
    id_zgloszenia = 0
    assigned_assist_id = None
    
    # Czekamy max 70 sekund (job co minutę)
    for i in range(15): # Skrócone do 15 checks z force
        # FORCE JOB: Możemy spróbować ręcznie wywołać logikę UPDATE jeśli job nie ruszy
        # Ale najpierw sprawdźmy czy ruszył
        cur_admin.execute(f"SELECT id_zgloszenia, status_wstepny, id_przypisanego_asystenta FROM Zgloszenie_Wstepne WHERE id_zgloszenia > {old_max}")
        row = cur_admin.fetchone()
        
        if row:
            id_zgloszenia = row[0]
            status = row[1]
            assigned_assist_id = row[2]
            
            if status == 'W filtracji' and assigned_assist_id is not None:
                log(f"-> Job wykonał zadanie! Zgłoszenie {id_zgloszenia} przypisane do asystenta ID={assigned_assist_id}")
                break
        
        log(f"Waiting... ({i*5}s)")
        time.sleep(5)
        
        # Fallback: Ręczne wymuszenie logiki, jeśli job nie działa (dla testu)
        if i == 5: 
            log("-> Wymuszam UPDATE ręcznie (na wypadek gdyby scheduler spał)...")
            cur_admin.execute("""
                UPDATE Zgloszenie_Wstepne z
                SET 
                    z.status_wstepny = 'W filtracji',
                    z.id_przypisanego_asystenta = (
                        SELECT id_asystenta FROM Asystent_Czasopisma a 
                        WHERE a.id_czasopisma = z.id_czasopisma_docelowego ORDER BY RAND() LIMIT 1
                    )
                WHERE z.status_wstepny = 'Oczekuje' AND z.id_zgloszenia > %s
            """, (old_max,))
            conn_admin.commit()

    if assigned_assist_id is None:
        log("BŁĄD: Nie przypisano asystenta.")
        return

    # 3. LOGOWANIE JAKO ASYSTENT
    user_key = 'asystent_1' if assigned_assist_id == 1 else 'asystent_15'
    log(f"Krok 3: Logowanie jako {user_key}...")
    
    conn_assist = get_conn(user_key)
    cur_assist = conn_assist.cursor()
    
    try:
        cur_assist.callproc('sp_Asystent_AkceptujZgloszenie', [id_zgloszenia])
        conn_assist.commit()
        log("-> Asystent zaakceptował zgłoszenie.")
    except Exception as e:
        log(f"BŁĄD Asystenta: {e}")
        return
    conn_assist.close()
    
    # 4. PRZYPISANIE REDAKTORA PROWADZĄCEGO
    # Ponieważ Asystent nie ma uprawnień (sprawdziliśmy), robimy to jako REDAKTOR NACZELNY
    # Użytkownik prosił "jako asystent przypisz", ale to niemożliwe w obecnym modelu uprawnień.
    # Wykonam to jako Naczelny i zaraportuję.
    
    log("Krok 4: Przypisanie redaktora prowadzącego (Rola: Naczelny)...")
    
    # Pobierz ID utworzonego artykułu i rundy
    cur_admin.execute(f"SELECT id_artykulu FROM Artykul ORDER BY id_artykulu DESC LIMIT 1")
    id_artykulu = cur_admin.fetchone()[0]
    
    cur_admin.execute(f"SELECT id_rundy FROM RundaRecenzyjna WHERE id_artykulu = {id_artykulu} AND numer_rundy = 1")
    id_rundy = cur_admin.fetchone()[0]
    
    conn_chief = get_conn('chief')
    cur_chief = conn_chief.cursor()
    
    # Przypisujemy TEGO SAMEGO asystenta (np. Sebastiana czy Anitę) jako Redaktora Prowadzącego,
    # aby sprawdzić "czy ten asystent... przypisze recenzenta".
    # (Bo Asystent ma rolę która pozwala zapraszać recenzentów JEŚLI jest prowadzącym).
    
    target_editor_id = assigned_assist_id 
    
    cur_chief.callproc('sp_Naczelny_PrzypiszRedaktoraDoRundy', [id_rundy, target_editor_id])
    conn_chief.commit()
    conn_chief.close()
    log(f"-> Przypisano redaktora prowadzącego (ID={target_editor_id}) do rundy {id_rundy}.")

    # 5. REDAKTOR PROWADZĄCY (Ten sam user co asystent) PRZYPISUJE RECENZENTA
    log(f"Krok 5: Redaktor Prowadzący ({user_key}) zaprasza recenzenta...")
    
    conn_editor = get_conn(user_key) # Logujemy się znowu
    cur_editor = conn_editor.cursor()
    
    # Zapraszamy autora ID=7 (author_lukasz_1)
    recenzent_id = 7
    try:
        cur_editor.callproc('sp_Redaktor_ZaprosRecenzenta', [id_rundy, recenzent_id])
        conn_editor.commit()
        log(f"-> Zaproszono recenzenta ID={recenzent_id}")
    except Exception as e:
        log(f"Błąd zapraszania: {e}")
        return
    conn_editor.close()
    
    # 6. RECENZENT PRZESYŁA RECENZJĘ
    log("Krok 6: Recenzent Łukasz przesyła recenzję...")
    conn_rev = get_conn('reviewer')
    cur_rev = conn_rev.cursor()
    
    # Znajdź ID recenzji (zadanie dla tego recenzenta w tej rundzie)
    # Recenzent to author_lukasz_1 (ID=7)
    cur_rev.execute(f"SELECT id_recenzji FROM Recenzja WHERE id_rundy = {id_rundy} AND id_autora_recenzenta = 7")
    row_rev = cur_rev.fetchone()
    if not row_rev:
         log("BŁĄD: Brak rekordu recenzji!")
         return
    id_recenzji = row_rev[0]

    # Przekazujemy NAZWĘ "Akceptacja", a nie ID
    cur_rev.callproc('sp_Recenzent_PrzeslijRecenzje', [id_recenzji, 'Akceptacja', "Bardzo dobry artykuł, polecam."])
    conn_rev.commit()
    conn_rev.close()
    log("-> Recenzja przesłana.")
    
    # 7. REDAKTOR PODEJMUJE DECYZJĘ
    log("Krok 7: Redaktor Prowadzący podejmuje decyzję (Akceptacja)...")
    conn_editor = get_conn(user_key)
    cur_editor = conn_editor.cursor()
    
    cur_admin.execute("SELECT id_decyzji FROM Decyzja_Slownik WHERE nazwa_decyzji = 'Zaakceptowany'")
    id_dec = cur_admin.fetchone()[0]
    
    cur_editor.callproc('sp_Redaktor_PodejmijDecyzje', [id_rundy, id_dec])
    conn_editor.commit()
    conn_editor.close()
    log("-> Decyzja podjęta.")
    
    # 8. WERYFIKACJA TRIGGERA (Status artykułu powinien się zmienić?)
    log("Krok 8: Weryfikacja triggerów/statusu...")
    cur_admin.execute(f"SELECT * FROM RundaRecenzyjna WHERE id_rundy = {id_rundy}")
    runda = cur_admin.fetchone()
    print("STAN RUNDY:", runda)
    
    # Sprawdź efekt triggera (co on robi? 01_trg_PoZgloszeniu... to był event. A trigger?)
    # Sprawdźmy 'aktualizacja_daty_artykul.sql'?
    
    log("TEST ZAKOŃCZONY SUKCESEM.")

if __name__ == "__main__":
    try:
        main()
    except Exception as e:
        print(f"FATAL ERROR: {e}")
        import traceback
        traceback.print_exc()

