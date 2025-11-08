DELIMITER $$

-- Nowa nazwa procedury
CREATE PROCEDURE sp_PobierzWszystkieMojeArtykuly()
BEGIN
    DECLARE v_id_autora INT;

    -- Krok 1: Znajdź ID zalogowanego użytkownika
    SELECT id_autora INTO v_id_autora
    FROM Mapowanie_Uzytkownik_Autor
    WHERE nazwa_uzytkownika_db = USER()
    LIMIT 1;

    -- Krok 2: Jeśli znaleziono, zwróć jego artykuły
    IF v_id_autora IS NOT NULL THEN
        SELECT 
            a.tytul,
            a.doi,
            rr.numer_rundy,
            ds.nazwa_decyzji AS aktualny_status,
            -- Dodajmy informację, czy jest opublikowany
            IF(a.id_czasopisma IS NULL, 'W recenzji', 'Opublikowany') AS stan_publikacji
        FROM 
            Artykul a
        JOIN 
            Artykul_Autor aa ON a.id_artykulu = aa.id_artykulu
        -- Używamy LEFT JOIN na wypadek, gdyby artykuł był dodany, ale nie miał jeszcze rundy
        LEFT JOIN 
            RundaRecenzyjna rr ON a.id_artykulu = rr.id_artykulu
        LEFT JOIN 
            Decyzja_Slownik ds ON rr.id_decyzji = ds.id_decyzji
        WHERE
            -- Warunek 1: Artykuł jest powiązany z zalogowanym autorem
            aa.id_autora = v_id_autora
            
            -- USUNIĘTY WARUNEK: AND a.id_czasopisma IS NULL
            
            -- Warunek 3: Pokazuj tylko najnowszy status (najnowszą rundę)
            -- lub pokaż artykuł, jeśli nie ma jeszcze żadnej rundy (rr.id_rundy IS NULL)
            AND (rr.numer_rundy = (
                SELECT MAX(rr_inner.numer_rundy) 
                FROM RundaRecenzyjna rr_inner 
                WHERE rr_inner.id_artykulu = a.id_artykulu
            ) OR rr.id_rundy IS NULL); -- Pokaż też artykuły bez rund
    END IF;

END$$

DELIMITER ;