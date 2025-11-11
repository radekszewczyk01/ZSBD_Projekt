--
-- Konwersja końcowej części Routines dla bazy 'rims_v2'
--

-- -----------------------------------------------------------------------------
-- Procedura: sp_Recenzent_PrzeslijRecenzje
-- -----------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE "sp_Recenzent_PrzeslijRecenzje"(
    IN p_id_recenzji INT,                       
    IN p_nazwa_rekomendacji VARCHAR(100),       
    IN p_tresc_recenzji TEXT                    
) AS $$
DECLARE
    v_id_recenzenta INT;
    v_id_rekomendacji INT;
    v_przypisany_recenzent INT;
BEGIN
    
    SELECT id_autora INTO v_id_recenzenta
    FROM "Mapowanie_Uzytkownik_Autor"
    WHERE nazwa_uzytkownika_db = session_user LIMIT 1;

    
    SELECT id_rekomendacji INTO v_id_rekomendacji
    FROM "Rekomendacja_Slownik"
    WHERE nazwa_rekomendacji = p_nazwa_rekomendacji;
    
    IF v_id_rekomendacji IS NULL THEN
        RAISE EXCEPTION 'Błąd: Podana nazwa rekomendacji jest nieprawidłowa.';
    END IF;

    
    SELECT id_autora_recenzenta INTO v_przypisany_recenzent
    FROM "Recenzja"
    WHERE id_recenzji = p_id_recenzji
    FOR UPDATE; 

    
    IF v_przypisany_recenzent IS NULL OR v_id_recenzenta <> v_przypisany_recenzent THEN
        RAISE EXCEPTION 'Błąd: Nie jesteś przypisany do wykonania tej recenzji.';
    END IF;
    
    
    UPDATE "Recenzja"
    SET
        id_rekomendacji = v_id_rekomendacji,
        tresc_recenzji = p_tresc_recenzji,
        data_otrzymania = CURRENT_DATE
    WHERE
        id_recenzji = p_id_recenzji;

    RAISE NOTICE 'Sukces: Recenzja została przesłana.';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- -----------------------------------------------------------------------------
-- Procedura: sp_Redaktor_PodejmijDecyzje
-- -----------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE "sp_Redaktor_PodejmijDecyzje"(
    IN p_id_rundy INT,                    
    IN p_nazwa_decyzji VARCHAR(100)       
) AS $$
DECLARE
    v_id_redaktora_zalogowanego INT;
    v_id_redaktora_prowadzacego INT;
    v_id_decyzji_nowej INT;
    v_data_zakonczenia DATE DEFAULT NULL;
BEGIN
    
    SELECT id_autora INTO v_id_redaktora_zalogowanego
    FROM "Mapowanie_Uzytkownik_Autor"
    WHERE nazwa_uzytkownika_db = session_user LIMIT 1;

    
    SELECT id_redaktora_prowadzacego INTO v_id_redaktora_prowadzacego
    FROM "RundaRecenzyjna"
    WHERE id_rundy = p_id_rundy
    FOR UPDATE; 

    
    IF v_id_redaktora_zalogowanego IS NULL OR v_id_redaktora_zalogowanego <> v_id_redaktora_prowadzacego THEN
        RAISE EXCEPTION 'Błąd: Nie jesteś redaktorem prowadzącym tej rundy.';
    END IF;

    
    SELECT id_decyzji INTO v_id_decyzji_nowej
    FROM "Decyzja_Slownik"
    WHERE nazwa_decyzji = p_nazwa_decyzji;
    
    IF v_id_decyzji_nowej IS NULL THEN
        RAISE EXCEPTION 'Błąd: Podana nazwa decyzji jest nieprawidłowa.';
    END IF;

    
    IF p_nazwa_decyzji IN ('Zaakceptowany', 'Odrzucony') THEN
        v_data_zakonczenia := CURRENT_DATE;
    END IF;

    
    UPDATE "RundaRecenzyjna"
    SET
        id_decyzji = v_id_decyzji_nowej,
        data_zakonczenia = v_data_zakonczenia
    WHERE
        id_rundy = p_id_rundy;
        
    RAISE NOTICE 'Sukces: Zmieniono status rundy ID % na "%".', p_id_rundy, p_nazwa_decyzji;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
CREATE OR REPLACE FUNCTION "sp_Redaktor_SprawdzStatusyRecenzji"(
    IN p_id_rundy INT 
)
RETURNS TABLE (
    id_recenzji INT,
    "Imie_Recenzenta" VARCHAR(100),
    "Nazwisko_Recenzenta" VARCHAR(150),
    "Status" TEXT,
    "Rekomendacja" VARCHAR(100),
    data_otrzymania DATE
) AS $$
DECLARE
    v_id_redaktora_zalogowanego INT;
    v_id_redaktora_prowadzacego INT;
BEGIN
    
    SELECT id_autora INTO v_id_redaktora_zalogowanego
    FROM "Mapowanie_Uzytkownik_Autor"
    WHERE nazwa_uzytkownika_db = session_user LIMIT 1;

    
    SELECT id_redaktora_prowadzacego INTO v_id_redaktora_prowadzacego
    FROM "RundaRecenzyjna"
    WHERE id_rundy = p_id_rundy;

    
    IF v_id_redaktora_zalogowanego IS NULL OR v_id_redaktora_zalogowanego <> v_id_redaktora_prowadzacego THEN
        RAISE EXCEPTION 'Błąd: Nie jesteś redaktorem prowadzącym tej rundy.';
    END IF;

    
    RETURN QUERY
    SELECT 
        rec.id_recenzji,
        a.imie AS "Imie_Recenzenta",
        a.nazwisko AS "Nazwisko_Recenzenta",
        
        -- Konwersja IF() z MySQL na CASE WHEN
        CASE 
            WHEN rec.id_rekomendacji IS NULL THEN 'OCZEKUJE NA RECENZJĘ'
            ELSE 'RECENZJA PRZESŁANA' 
        END AS "Status",
           
        rs.nazwa_rekomendacji AS "Rekomendacja",
        rec.data_otrzymania
        
    FROM "Recenzja" rec
    JOIN "Autor" a ON rec.id_autora_recenzenta = a.id_autora
    LEFT JOIN "Rekomendacja_Slownik" rs ON rec.id_rekomendacji = rs.id_rekomendacji
    WHERE rec.id_rundy = p_id_rundy;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- -----------------------------------------------------------------------------
-- Procedura: sp_Redaktor_ZaprosRecenzenta
-- (Naprawiono brak 'INSERT INTO' i 'ON DUPLICATE KEY' na 'ON CONFLICT')
-- -----------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE "sp_Redaktor_ZaprosRecenzenta"(
    IN p_id_rundy INT,            
    IN p_id_autora_recenzenta INT 
) AS $$
DECLARE
    v_id_redaktora_zalogowanego INT;
    v_id_redaktora_prowadzacego INT;
    v_id_artykulu INT;
BEGIN
    
    SELECT id_autora INTO v_id_redaktora_zalogowanego
    FROM "Mapowanie_Uzytkownik_Autor"
    WHERE nazwa_uzytkownika_db = session_user LIMIT 1;

    
    SELECT id_redaktora_prowadzacego, id_artykulu
    INTO v_id_redaktora_prowadzacego, v_id_artykulu
    FROM "RundaRecenzyjna"
    WHERE id_rundy = p_id_rundy;

    
    IF v_id_redaktora_zalogowanego IS NULL OR v_id_redaktora_zalogowanego <> v_id_redaktora_prowadzacego THEN
        RAISE EXCEPTION 'Błąd: Nie jesteś redaktorem prowadzącym tej rundy.';
    END IF;

    
    IF EXISTS (SELECT 1 FROM "Artykul_Autor" WHERE id_artykulu = v_id_artykulu AND id_autora = p_id_autora_recenzenta) THEN
        RAISE EXCEPTION 'Błąd: Nie można zaprosić autora artykułu do jego recenzowania.';
    END IF;

    
    -- Poprawiony błąd (brak 'INSERT INTO') i konwersja 'ON DUPLICATE KEY'
    INSERT INTO "Recenzja"
        (id_rundy, id_autora_recenzenta, id_rekomendacji, data_otrzymania)
    VALUES
        (p_id_rundy, p_id_autora_recenzenta, NULL, NULL)
    -- Klucz UNIQUE w "Recenzja" to (id_rundy, id_autora_recenzenta)
    ON CONFLICT (id_rundy, id_autora_recenzenta) 
    DO UPDATE SET data_otrzymania = NULL; -- Przykładowa akcja, aby obsłużyć duplikat

    RAISE NOTICE 'Sukces: Zaproszono recenzenta.';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- -----------------------------------------------------------------------------
-- Funkcja: sp_Redaktor_ZnajdzRecenzentow (była procedura)
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION "sp_Redaktor_ZnajdzRecenzentow"(
    IN p_id_artykulu INT
)
RETURNS TABLE (
    id_autora INT,
    imie VARCHAR(100),
    nazwisko VARCHAR(150),
    orcid VARCHAR(50),
    "Pasujaca_Dyscyplina" VARCHAR(100)
) AS $$
DECLARE
    v_id_asystenta INT;
    v_id_czasopisma_artykulu INT;
    v_ma_dostep BOOLEAN DEFAULT FALSE;
BEGIN
    
    -- === POPRAWKA TUTAJ (LINIA 8) ===
    -- Dodaliśmy 'AS map' i 'map.id_autora', aby rozwiązać niejednoznaczność
    SELECT map.id_autora INTO v_id_asystenta
    FROM "Mapowanie_Uzytkownik_Autor" AS map
    WHERE map.nazwa_uzytkownika_db = session_user LIMIT 1;

    
    SELECT id_czasopisma INTO v_id_czasopisma_artykulu
    FROM "Artykul"
    WHERE id_artykulu = p_id_artykulu;
    
    IF v_id_czasopisma_artykulu IS NULL THEN
        RAISE EXCEPTION 'Błąd: Artykuł nie został znaleziony lub nie jest przypisany do żadnego czasopisma.';
    END IF;

    
    SELECT EXISTS (
        SELECT 1
        FROM "Asystent_Czasopisma"
        WHERE id_asystenta = v_id_asystenta
          AND id_czasopisma = v_id_czasopisma_artykulu
    ) INTO v_ma_dostep;

    
    IF NOT v_ma_dostep THEN
        RAISE EXCEPTION 'Błąd: Nie masz uprawnień do zarządzania artykułami tego czasopisma.';
    END IF;

    
    RETURN QUERY
    SELECT DISTINCT
        a.id_autora,
        a.imie,
        a.nazwisko,
        a.orcid,
        d.nazwa AS "Pasujaca_Dyscyplina"
    FROM "Autor" a
    JOIN "Autor_Dyscyplina" ad ON a.id_autora = ad.id_autora
    JOIN "Artykul_Dyscyplina" art_d ON ad.id_dyscypliny = art_d.id_dyscypliny
    JOIN "Dyscypliny" d ON ad.id_dyscypliny = d.id_dyscypliny
    WHERE
        art_d.id_artykulu = p_id_artykulu
        AND a.id_autora NOT IN (
            SELECT aa.id_autora FROM "Artykul_Autor" aa WHERE aa.id_artykulu = p_id_artykulu
        );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- -----------------------------------------------------------------------------
-- Procedura: sp_StworzUzytkownikaAsystenta
-- (Logika zmieniona na EXECUTE format() i dostosowana do mapowania PG)
-- -----------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE "sp_StworzUzytkownikaAsystenta"(
    IN p_nazwa_uzytkownika VARCHAR(100), 
    IN p_haslo VARCHAR(100),            
    IN p_id_autora INT                  
) AS $$
BEGIN
    
    -- %I bezpiecznie cytuje identyfikator (nazwę użytkownika), %L bezpiecznie cytuje literał (hasło)
    EXECUTE format('CREATE USER %I WITH PASSWORD %L', p_nazwa_uzytkownika, p_haslo);

    -- Zakładamy, że rola "RolaAsystenta" istnieje w bazie PostgreSQL
    EXECUTE format('GRANT "RolaAsystenta" TO %I', p_nazwa_uzytkownika);

    -- Poprawiony błąd (brak 'INSERT INTO') i dostosowanie do logiki PG (bez '@localhost')
    INSERT INTO "Mapowanie_Uzytkownik_Autor" (nazwa_uzytkownika_db, id_autora)
    VALUES (p_nazwa_uzytkownika, p_id_autora);
    
    RAISE NOTICE 'Sukces: Stworzono użytkownika-ASYSTENTA % i powiązano z id_autora = %', p_nazwa_uzytkownika, p_id_autora;
    
EXCEPTION
    WHEN OTHERS THEN
        RAISE; 
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- -----------------------------------------------------------------------------
-- Procedura: sp_StworzUzytkownikaAutora
-- (Analogiczne zmiany jak powyżej)
-- -----------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE "sp_StworzUzytkownikaAutora"(
    IN p_nazwa_uzytkownika VARCHAR(100), 
    IN p_haslo VARCHAR(100),            
    IN p_id_autora INT                  
) AS $$
BEGIN
    
    EXECUTE format('CREATE USER %I WITH PASSWORD %L', p_nazwa_uzytkownika, p_haslo);
    
    -- Zakładamy, że rola "RolaAutora" istnieje w bazie PostgreSQL
    EXECUTE format('GRANT "RolaAutora" TO %I', p_nazwa_uzytkownika);

    -- Poprawiony błąd (brak 'INSERT INTO')
    INSERT INTO "Mapowanie_Uzytkownik_Autor" (nazwa_uzytkownika_db, id_autora)
    VALUES (p_nazwa_uzytkownika, p_id_autora);
    
    RAISE NOTICE 'Sukces: Stworzono użytkownika % i powiązano z id_autora = %', p_nazwa_uzytkownika, p_id_autora;

EXCEPTION
    WHEN OTHERS THEN
        RAISE; 
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- -----------------------------------------------------------------------------
-- Procedura: sp_StworzUzytkownika_RedaktorNaczelny
-- (Analogiczne zmiany + obsługa ROW_COUNT())
-- -----------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE "sp_StworzUzytkownika_RedaktorNaczelny"(
    IN p_nazwa_uzytkownika VARCHAR(100), 
    IN p_haslo VARCHAR(100),             
    IN p_id_autora INT,                  
    IN p_id_czasopisma INT               
) AS $$
DECLARE
    v_rows_affected INT;
BEGIN
    
    EXECUTE format('CREATE USER %I WITH PASSWORD %L', p_nazwa_uzytkownika, p_haslo);

    -- Zakładamy, że role istnieją w bazie PostgreSQL
    EXECUTE format('GRANT "RolaAutora" TO %I', p_nazwa_uzytkownika);
    EXECUTE format('GRANT "RolaAsystenta" TO %I', p_nazwa_uzytkownika);
    EXECUTE format('GRANT "RolaRedaktoraNaczelnego" TO %I', p_nazwa_uzytkownika); 

    -- Poprawiony błąd (brak 'INSERT INTO')
    INSERT INTO "Mapowanie_Uzytkownik_Autor" (nazwa_uzytkownika_db, id_autora)
    VALUES (p_nazwa_uzytkownika, p_id_autora);
    
    
    UPDATE "Czasopismo"
    SET 
        id_redaktora_naczelnego = p_id_autora
    WHERE 
        id_czasopisma = p_id_czasopisma;
        
    -- Sprawdzenie, czy UPDATE się powiódł (odpowiednik ROW_COUNT())
    GET DIAGNOSTICS v_rows_affected = ROW_COUNT;
    
    IF v_rows_affected = 0 THEN
        RAISE EXCEPTION 'Błąd: Nie znaleziono czasopisma o podanym ID. Transakcja wycofana.';
    END IF;

    
    RAISE NOTICE 'Sukces: Stworzono użytkownika % i mianowano redaktorem naczelnym czasopisma ID = %', p_nazwa_uzytkownika, p_id_czasopisma;

EXCEPTION
    WHEN OTHERS THEN
        RAISE; 
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

--
-- Struktury widoków (Views) i zakończenie zrzutu (Dump completed)
-- zostały pominięte, ponieważ oryginalny plik nie zawierał ich definicji.
--