--
-- Konwersja Routines dla bazy 'rims_v2'
--

-- -----------------------------------------------------------------------------
-- Funkcja: fn_SprawdzZgodnoscDyscyplin
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION "fn_SprawdzZgodnoscDyscyplin"(
    p_id_zgloszenia INT
) RETURNS BOOLEAN AS $$
DECLARE
    v_zgodnosc_znaleziona BOOLEAN DEFAULT FALSE;
BEGIN
    
    SELECT EXISTS (
        SELECT 1
        FROM "Zgloszenie_Wstepne_Autor" zwa 
        JOIN "Autor_Dyscyplina" ad ON zwa.id_autora = ad.id_autora 
        JOIN "Zgloszenie_Wstepne_Dyscyplina" zwd ON ad.id_dyscypliny = zwd.id_dyscypliny 
        WHERE 
            zwa.id_zgloszenia = p_id_zgloszenia
            AND zwd.id_zgloszenia = p_id_zgloszenia
    ) INTO v_zgodnosc_znaleziona;
    
    RETURN v_zgodnosc_znaleziona;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- -----------------------------------------------------------------------------
-- Procedura: sp_Asystent_AkceptujZgloszenie
-- (UWAGA: Naprawiono brakujące 'INSERT' i dostosowano 'LAST_INSERT_ID')
-- -----------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE "sp_Asystent_AkceptujZgloszenie"(
    IN p_id_zgloszenia INT
) AS $$
DECLARE
    v_tytul VARCHAR(500);
    v_doi VARCHAR(100);
    v_rok INT;
    v_id_czasopisma INT;
    v_id_artykulu INT;
    v_id_decyzji_startowej INT;
    v_id_asystenta INT;
BEGIN
    
    SELECT id_autora INTO v_id_asystenta
    FROM "Mapowanie_Uzytkownik_Autor"
    WHERE nazwa_uzytkownika_db = session_user -- USER() z MySQL to session_user w PG
    LIMIT 1;

    
    SELECT tytul, doi_proponowane, rok_proponowany, id_czasopisma_docelowego
    INTO v_tytul, v_doi, v_rok, v_id_czasopisma
    FROM "Zgloszenie_Wstepne"
    WHERE id_zgloszenia = p_id_zgloszenia 
      AND status_wstepny = 'W filtracji'
      AND id_przypisanego_asystenta = v_id_asystenta
    FOR UPDATE;

    IF v_tytul IS NULL THEN
        RAISE EXCEPTION 'Błąd: Nie znaleziono zgłoszenia, ma zły status, lub nie jest przypisane do Ciebie.';
    END IF;

    
    SELECT id_decyzji INTO v_id_decyzji_startowej
    FROM "Decyzja_Slownik" WHERE nazwa_decyzji = 'W trakcie' LIMIT 1;

    -- W PostgreSQL procedury domyślnie zarządzają transakcjami
    
    -- Poprawiony INSERT (brakowało 'INSERT INTO...')
    -- Użycie 'RETURNING' zamiast 'LAST_INSERT_ID()'
    INSERT INTO "Artykul" (tytul, doi, rok_publikacji, data_ostatniej_aktualizacji, id_czasopisma)
    VALUES (v_tytul, v_doi, v_rok, CURRENT_DATE, v_id_czasopisma)
    RETURNING "id_artykulu" INTO v_id_artykulu;

    -- Poprawiony INSERT (brakowało 'INSERT INTO...')
    INSERT INTO "Artykul_Autor" (id_artykulu, id_autora, kolejnosc_autora)
    SELECT v_id_artykulu, id_autora, kolejnosc_autora
    FROM "Zgloszenie_Wstepne_Autor"
    WHERE id_zgloszenia = p_id_zgloszenia;

    -- Poprawiony INSERT (brakowało 'INSERT INTO...')
    INSERT INTO "Artykul_Dyscyplina" (id_artykulu, id_dyscypliny)
    SELECT v_id_artykulu, id_dyscypliny
    FROM "Zgloszenie_Wstepne_Dyscyplina"
    WHERE id_zgloszenia = p_id_zgloszenia;

    -- Poprawiony INSERT (brakowało 'INSERT INTO...')
    INSERT INTO "RundaRecenzyjna" (id_artykulu, numer_rundy, data_rozpoczecia, id_decyzji)
    VALUES (v_id_artykulu, 1, CURRENT_DATE, v_id_decyzji_startowej);

    
    UPDATE "Zgloszenie_Wstepne"
    SET status_wstepny = 'Zaakceptowane'
    WHERE id_zgloszenia = p_id_zgloszenia;

    
    RAISE NOTICE 'Zgłoszenie zostało zaakceptowane i w pełni przeniesione do systemu.';
    
EXCEPTION
    WHEN OTHERS THEN
        RAISE; -- Przekaż błąd dalej
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- -----------------------------------------------------------------------------
-- Procedura: sp_Autor_Demo_ZglosDoCzasopisma
-- (UWAGA: Naprawiono błędy, zastąpiono UUID_SHORT() i RAND())
-- -----------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE "sp_Autor_Demo_ZglosDoCzasopisma"(
    IN p_nazwa_czasopisma VARCHAR(255) 
) AS $$
DECLARE
    v_id_autora_zglaszajacego INT;
    v_id_zgloszenia INT;
    v_id_czasopisma INT; 
    v_wspolautor_id_1 INT;
    v_wspolautor_id_2 INT;
    v_dyscyplina_id_1 INT;
    v_dyscyplina_id_2 INT;
    v_tytul VARCHAR(500);
    v_doi VARCHAR(100);
    v_rok INT DEFAULT EXTRACT(YEAR FROM CURRENT_DATE);
BEGIN
    
    SELECT id_autora INTO v_id_autora_zglaszajacego
    FROM "Mapowanie_Uzytkownik_Autor"
    WHERE nazwa_uzytkownika_db = session_user
    LIMIT 1;

    IF v_id_autora_zglaszajacego IS NULL THEN
        RAISE EXCEPTION 'Błąd: Zalogowany użytkownik nie jest zmapowany do autora.';
    END IF;
    
    SELECT id_czasopisma INTO v_id_czasopisma 
    FROM "Czasopismo" 
    WHERE tytul = p_nazwa_czasopisma 
    LIMIT 1;

    IF v_id_czasopisma IS NULL THEN
        RAISE EXCEPTION 'Błąd: Czasopismo o podanej nazwie nie zostało znalezione.';
    END IF;

    -- Zastąpienie UUID_SHORT() losową liczbą
    v_tytul := CONCAT('Losowy artykuł testowy (', (random() * 1000000000)::bigint, ')');
    v_doi := CONCAT('10.9999/demo.', (random() * 1000000000)::bigint);
    
    SELECT id_autora INTO v_wspolautor_id_1 FROM "Autor" 
    WHERE id_autora <> v_id_autora_zglaszajacego ORDER BY RANDOM() LIMIT 1;
    
    SELECT id_autora INTO v_wspolautor_id_2 FROM "Autor" 
    WHERE id_autora <> v_id_autora_zglaszajacego AND id_autora <> v_wspolautor_id_1 ORDER BY RANDOM() LIMIT 1;

    SELECT id_dyscypliny INTO v_dyscyplina_id_1 FROM "Dyscypliny" ORDER BY RANDOM() LIMIT 1;
    SELECT id_dyscypliny INTO v_dyscyplina_id_2 FROM "Dyscypliny" WHERE id_dyscypliny <> v_dyscyplina_id_1 ORDER BY RANDOM() LIMIT 1;

    -- Poprawiony INSERT (brakowało 'INSERT INTO...')
    INSERT INTO "Zgloszenie_Wstepne"
        (tytul, doi_proponowane, rok_proponowany, id_autora_zglaszajacego, id_czasopisma_docelowego, data_zgloszenia, status_wstepny)
    VALUES 
        (v_tytul, v_doi, v_rok, v_id_autora_zglaszajacego, v_id_czasopisma, CURRENT_DATE, 'Oczekuje')
    RETURNING "id_zgloszenia" INTO v_id_zgloszenia;

    -- Poprawiony INSERT (brakowało 'INSERT INTO...')
    INSERT INTO "Zgloszenie_Wstepne_Autor" (id_zgloszenia, id_autora, kolejnosc_autora)
    VALUES 
        (v_id_zgloszenia, v_id_autora_zglaszajacego, 1),
        (v_id_zgloszenia, v_wspolautor_id_1, 2),
        (v_id_zgloszenia, v_wspolautor_id_2, 3);

    -- Poprawiony INSERT (brakowało 'INSERT INTO...')
    INSERT INTO "Zgloszenie_Wstepne_Dyscyplina" (id_zgloszenia, id_dyscypliny)
    VALUES
        (v_id_zgloszenia, v_dyscyplina_id_1),
        (v_id_zgloszenia, v_dyscyplina_id_2);

    RAISE NOTICE 'Sukces: Zgłoszono losowy artykuł (ID Zgłoszenia: %) do czasopisma "%".', v_id_zgloszenia, p_nazwa_czasopisma;

EXCEPTION
    WHEN OTHERS THEN
        RAISE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- -----------------------------------------------------------------------------
-- Procedura: sp_Autor_Demo_ZglosDoCzasopisma_Poprawne
-- (Analogiczne poprawki jak powyżej)
-- -----------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE "sp_Autor_Demo_ZglosDoCzasopisma_Poprawne"(
    IN p_nazwa_czasopisma VARCHAR(255) 
) AS $$
DECLARE
    v_id_autora_zglaszajacego INT;
    v_id_zgloszenia INT;
    v_id_czasopisma INT;
    v_wspolautor_id_1 INT;
    v_wspolautor_id_2 INT;
    v_dyscyplina_id_1 INT;
    v_dyscyplina_id_2 INT;
    v_tytul VARCHAR(500);
    v_doi VARCHAR(100);
    v_rok INT DEFAULT EXTRACT(YEAR FROM CURRENT_DATE);
BEGIN
    
    SELECT id_autora INTO v_id_autora_zglaszajacego
    FROM "Mapowanie_Uzytkownik_Autor"
    WHERE nazwa_uzytkownika_db = session_user
    LIMIT 1;

    IF v_id_autora_zglaszajacego IS NULL THEN
        RAISE EXCEPTION 'Błąd: Zalogowany użytkownik nie jest zmapowany do autora.';
    END IF;

    
    SELECT id_czasopisma INTO v_id_czasopisma 
    FROM "Czasopismo" 
    WHERE tytul = p_nazwa_czasopisma 
    LIMIT 1;

    IF v_id_czasopisma IS NULL THEN
        RAISE EXCEPTION 'Błąd: Czasopismo o podanej nazwie nie zostało znalezione.';
    END IF;

    
    v_tytul := CONCAT('Losowy artykuł testowy (', (random() * 1000000000)::bigint, ')');
    v_doi := CONCAT('10.9999/demo.', (random() * 1000000000)::bigint);
    
    SELECT id_autora INTO v_wspolautor_id_1 FROM "Autor" 
    WHERE id_autora <> v_id_autora_zglaszajacego ORDER BY RANDOM() LIMIT 1;
    
    SELECT id_autora INTO v_wspolautor_id_2 FROM "Autor" 
    WHERE id_autora <> v_id_autora_zglaszajacego AND id_autora <> v_wspolautor_id_1 ORDER BY RANDOM() LIMIT 1;

    
    SELECT id_dyscypliny INTO v_dyscyplina_id_1 
    FROM "Autor_Dyscyplina"
    WHERE id_autora IN (v_id_autora_zglaszajacego, v_wspolautor_id_1, v_wspolautor_id_2)
    ORDER BY RANDOM() 
    LIMIT 1;

    
    SELECT id_dyscypliny INTO v_dyscyplina_id_2 
    FROM "Autor_Dyscyplina"
    WHERE id_autora IN (v_id_autora_zglaszajacego, v_wspolautor_id_1, v_wspolautor_id_2)
      AND (v_dyscyplina_id_1 IS NULL OR id_dyscypliny <> v_dyscyplina_id_1) 
    ORDER BY RANDOM() 
    LIMIT 1;

    
    IF v_dyscyplina_id_1 IS NULL THEN
        SELECT id_dyscypliny INTO v_dyscyplina_id_1 FROM "Dyscypliny" ORDER BY RANDOM() LIMIT 1;
    END IF;
    
    IF v_dyscyplina_id_2 IS NULL THEN
        SELECT id_dyscypliny INTO v_dyscyplina_id_2 FROM "Dyscypliny" 
        WHERE id_dyscypliny <> v_dyscyplina_id_1 
        ORDER BY RANDOM() LIMIT 1;
    END IF;

    
    INSERT INTO "Zgloszenie_Wstepne"
        (tytul, doi_proponowane, rok_proponowany, id_autora_zglaszajacego, id_czasopisma_docelowego, data_zgloszenia, status_wstepny)
    VALUES 
        (v_tytul, v_doi, v_rok, v_id_autora_zglaszajacego, v_id_czasopisma, CURRENT_DATE, 'Oczekuje')
    RETURNING "id_zgloszenia" INTO v_id_zgloszenia;

    
    INSERT INTO "Zgloszenie_Wstepne_Autor" (id_zgloszenia, id_autora, kolejnosc_autora)
    VALUES 
        (v_id_zgloszenia, v_id_autora_zglaszajacego, 1),
        (v_id_zgloszenia, v_wspolautor_id_1, 2),
        (v_id_zgloszenia, v_wspolautor_id_2, 3);

    
    INSERT INTO "Zgloszenie_Wstepne_Dyscyplina" (id_zgloszenia, id_dyscypliny)
    VALUES
        (v_id_zgloszenia, v_dyscyplina_id_1),
        (v_id_zgloszenia, v_dyscyplina_id_2);

    
    RAISE NOTICE 'Sukces: Zgłoszono "poprawny" artykuł (ID Zgłoszenia: %) do czasopisma "%".', v_id_zgloszenia, p_nazwa_czasopisma;

EXCEPTION
    WHEN OTHERS THEN
        RAISE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- -----------------------------------------------------------------------------
-- Procedura: sp_Autor_ZglosArtykul
-- (UWAGA: Konwersja pętli WHILE i parsowania stringów z MySQL na PG)
-- -----------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE "sp_Autor_ZglosArtykul"(
    IN p_tytul VARCHAR(500),
    IN p_doi VARCHAR(100),
    IN p_rok INT,
    IN p_id_czasopisma_docelowego INT,
    IN p_wspolautorzy_csv TEXT, 
    IN p_dyscypliny_csv TEXT     
) AS $$
DECLARE
    v_id_autora_zglaszajacego INT;
    v_id_zgloszenia INT;
    v_id_single INT;
    v_idx INT;
    v_remaining_list TEXT;
BEGIN
    
    SELECT id_autora INTO v_id_autora_zglaszajacego
    FROM "Mapowanie_Uzytkownik_Autor"
    WHERE nazwa_uzytkownika_db = session_user
    LIMIT 1;
    
    IF v_id_autora_zglaszajacego IS NULL THEN
        RAISE EXCEPTION 'Błąd: Zalogowany użytkownik nie jest zmapowany do autora.';
    END IF;

    
    INSERT INTO "Zgloszenie_Wstepne"
        (tytul, doi_proponowane, rok_proponowany, id_autora_zglaszajacego, id_czasopisma_docelowego, data_zgloszenia, status_wstepny)
    VALUES
        (p_tytul, p_doi, p_rok, v_id_autora_zglaszajacego, p_id_czasopisma_docelowego, CURRENT_DATE, 'Oczekuje')
    RETURNING "id_zgloszenia" INTO v_id_zgloszenia;

    
    INSERT INTO "Zgloszenie_Wstepne_Autor" (id_zgloszenia, id_autora, kolejnosc_autora)
    VALUES (v_id_zgloszenia, v_id_autora_zglaszajacego, 1);
    
    
    v_remaining_list := p_wspolautorzy_csv;
    v_idx := 1;
    WHILE LENGTH(v_remaining_list) > 0 LOOP
        v_idx := v_idx + 1;
        -- SUBSTRING_INDEX(text, ',', 1) -> split_part(text, ',', 1)
        v_id_single := CAST(split_part(v_remaining_list, ',', 1) AS INT);
        
        IF v_id_single <> v_id_autora_zglaszajacego AND v_id_single > 0 THEN
            -- INSERT IGNORE -> ON CONFLICT DO NOTHING
            INSERT INTO "Zgloszenie_Wstepne_Autor" (id_zgloszenia, id_autora, kolejnosc_autora)
            VALUES (v_id_zgloszenia, v_id_single, v_idx)
            ON CONFLICT (id_zgloszenia, id_autora) DO NOTHING;
        END IF;
        
        -- LOCATE() -> STRPOS()
        IF STRPOS(v_remaining_list, ',') > 0 THEN
            v_remaining_list := SUBSTRING(v_remaining_list FROM STRPOS(v_remaining_list, ',') + 1);
        ELSE
            v_remaining_list := '';
        END IF;
    END LOOP;

    
    v_remaining_list := p_dyscypliny_csv;
    WHILE LENGTH(v_remaining_list) > 0 LOOP
        v_id_single := CAST(split_part(v_remaining_list, ',', 1) AS INT);
        IF v_id_single > 0 THEN
            INSERT INTO "Zgloszenie_Wstepne_Dyscyplina" (id_zgloszenia, id_dyscypliny)
            VALUES (v_id_zgloszenia, v_id_single)
            ON CONFLICT (id_zgloszenia, id_dyscypliny) DO NOTHING;
        END IF;
        
        IF STRPOS(v_remaining_list, ',') > 0 THEN
            v_remaining_list := SUBSTRING(v_remaining_list FROM STRPOS(v_remaining_list, ',') + 1);
        ELSE
            v_remaining_list := '';
        END IF;
    END LOOP;

    
    RAISE NOTICE 'Zgłoszenie zostało wysłane i oczekuje na weryfikację przez asystenta.';

EXCEPTION
    WHEN OTHERS THEN
        RAISE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- -----------------------------------------------------------------------------
-- Procedura: sp_Naczelny_PrzypiszRedaktoraDoRundy
-- -----------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE "sp_Naczelny_PrzypiszRedaktoraDoRundy"(
    IN p_id_rundy INT,            
    IN p_id_nowego_redaktora INT  
) AS $$
DECLARE
    v_id_naczelnego INT;
    v_id_czasopisma_naczelnego INT;
    v_id_czasopisma_artykulu INT;
    v_asystent_nalezy_do_czasopisma BOOLEAN DEFAULT FALSE;
BEGIN
    
    SELECT id_autora INTO v_id_naczelnego
    FROM "Mapowanie_Uzytkownik_Autor"
    WHERE nazwa_uzytkownika_db = session_user LIMIT 1;

    
    SELECT id_czasopisma INTO v_id_czasopisma_naczelnego
    FROM "Czasopismo"
    WHERE id_redaktora_naczelnego = v_id_naczelnego LIMIT 1;

    IF v_id_czasopisma_naczelnego IS NULL THEN
        RAISE EXCEPTION 'Błąd: Nie jesteś redaktorem naczelnym żadnego czasopisma.';
    END IF;

    
    SELECT a.id_czasopisma INTO v_id_czasopisma_artykulu
    FROM "Artykul" a
    JOIN "RundaRecenzyjna" rr ON a.id_artykulu = rr.id_artykulu
    WHERE rr.id_rundy = p_id_rundy;

    IF v_id_czasopisma_artykulu <> v_id_czasopisma_naczelnego THEN
        RAISE EXCEPTION 'Błąd: Ta runda recenzyjna nie dotyczy artykułu z Twojego czasopisma.';
    END IF;

    
    SELECT EXISTS (
        SELECT 1 
        FROM "Asystent_Czasopisma"
        WHERE id_asystenta = p_id_nowego_redaktora
          AND id_czasopisma = v_id_czasopisma_naczelnego
    ) INTO v_asystent_nalezy_do_czasopisma;
    
    IF NOT v_asystent_nalezy_do_czasopisma THEN
        RAISE EXCEPTION 'Błąd: Ten asystent (Redaktor Prowadzący) nie jest przypisany do Twojego czasopisma.';
    END IF;

    
    UPDATE "RundaRecenzyjna"
        SET id_redaktora_prowadzacego = p_id_nowego_redaktora
    WHERE 
        id_rundy = p_id_rundy;
        
    
    RAISE NOTICE 'Sukces: Przypisano redaktora (ID: %) do rundy (ID: %).', p_id_nowego_redaktora, p_id_rundy;

EXCEPTION
    WHEN OTHERS THEN
        RAISE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- -----------------------------------------------------------------------------
-- Funkcja: sp_PobierzAutorowDlaDyscypliny (była procedura)
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION "sp_PobierzAutorowDlaDyscypliny"(
    IN p_nazwa_dyscypliny VARCHAR(100) 
) 
RETURNS TABLE (
    imie_autora VARCHAR(100),
    nazwisko_autora VARCHAR(150),
    orcid VARCHAR(50)
) AS $$
BEGIN
    
    RETURN QUERY
    SELECT 
        pad.imie_autora,
        pad.nazwisko_autora,
        pad.orcid
    FROM 
        "Perspektywa_Autor_Dyscyplina" pad
    WHERE 
        
        pad.nazwa_dyscypliny = p_nazwa_dyscypliny;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- -----------------------------------------------------------------------------
-- Funkcja: sp_PobierzMojeSpecjalizacje (była procedura)
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION "sp_PobierzMojeSpecjalizacje"() 
RETURNS TABLE (
    nazwa_dyscypliny VARCHAR(100)
) AS $$
DECLARE
    v_id_autora INT;
BEGIN
    
    SELECT id_autora INTO v_id_autora
    FROM "Mapowanie_Uzytkownik_Autor"
    WHERE nazwa_uzytkownika_db = session_user
    LIMIT 1; 

    
    IF v_id_autora IS NOT NULL THEN
        
        RETURN QUERY
        SELECT 
            d.nazwa AS nazwa_dyscypliny
        FROM 
            "Autor_Dyscyplina" ad
        JOIN 
            "Dyscypliny" d ON ad.id_dyscypliny = d.id_dyscypliny
        WHERE 
            ad.id_autora = v_id_autora;
    END IF;
    -- Jeśli v_id_autora jest NULL, funkcja po prostu zwróci pustą tabelę, co jest poprawnym zachowaniem.
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- -----------------------------------------------------------------------------
-- Funkcja: sp_PobierzWszystkieMojeArtykuly (była procedura)
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION "sp_PobierzWszystkieMojeArtykuly"() 
RETURNS TABLE (
    tytul VARCHAR(500),
    doi VARCHAR(100),
    numer_rundy INT,
    aktualny_status VARCHAR(100),
    stan_publikacji TEXT
) AS $$
DECLARE
    v_id_autora INT;
BEGIN
    
    SELECT id_autora INTO v_id_autora
    FROM "Mapowanie_Uzytkownik_Autor"
    WHERE nazwa_uzytkownika_db = session_user
    LIMIT 1;

    
    IF v_id_autora IS NOT NULL THEN
        RETURN QUERY
        SELECT 
            a.tytul,
            a.doi,
            rr.numer_rundy,
            ds.nazwa_decyzji AS aktualny_status,
            
            -- Konwersja IF() z MySQL na CASE WHEN
            CASE 
                WHEN a.id_czasopisma IS NULL THEN 'W recenzji' 
                ELSE 'Opublikowany' 
            END AS stan_publikacji
        FROM 
            "Artykul" a
        JOIN 
            "Artykul_Autor" aa ON a.id_artykulu = aa.id_artykulu
        LEFT JOIN 
            "RundaRecenzyjna" rr ON a.id_artykulu = rr.id_artykulu
        LEFT JOIN 
            "Decyzja_Slownik" ds ON rr.id_decyzji = ds.id_decyzji
        WHERE
            aa.id_autora = v_id_autora
            AND (rr.numer_rundy = (
                SELECT MAX(rr_inner.numer_rundy) 
                FROM "RundaRecenzyjna" rr_inner 
                WHERE rr_inner.id_artykulu = a.id_artykulu
            ) OR rr.id_rundy IS NULL); 
    END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;