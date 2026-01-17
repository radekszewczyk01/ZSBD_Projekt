/*--- WYKONAJ JAKO ADMINISTRATOR ---*/
USE rims_v2;

CREATE OR REPLACE VIEW Perspektywa_Naczelnego_Artykuly_W_Systemie AS
SELECT DISTINCT -- DISTINCT, aby każdy artykuł pojawił się tylko raz
    a.id_artykulu,
    a.tytul,
    a.doi,
    
    -- Podzapytanie 1: Status (bez zmian)
    (SELECT ds.nazwa_decyzji
     FROM RundaRecenzyjna rr_sub
     JOIN Decyzja_Slownik ds ON rr_sub.id_decyzji = ds.id_decyzji
     WHERE rr_sub.id_artykulu = a.id_artykulu
     ORDER BY rr_sub.numer_rundy DESC
     LIMIT 1) AS 'Aktualny_Status',

    -- Podzapytanie 2: ID Rundy (NOWE)
    (SELECT rr_sub.id_rundy
     FROM RundaRecenzyjna rr_sub
     WHERE rr_sub.id_artykulu = a.id_artykulu
     ORDER BY rr_sub.numer_rundy DESC
     LIMIT 1) AS 'ID_Ostatniej_Rundy',

    -- Podzapytanie 3: ID Redaktora (NOWE)
    (SELECT rr_sub.id_redaktora_prowadzacego
     FROM RundaRecenzyjna rr_sub
     WHERE rr_sub.id_artykulu = a.id_artykulu
     ORDER BY rr_sub.numer_rundy DESC
     LIMIT 1) AS 'ID_Redaktora_Prowadzacego'
     
FROM Artykul a

-- Musimy połączyć się przez RundaRecenzyjna, aby odfiltrować artykuły bez rund
JOIN RundaRecenzyjna rr ON a.id_artykulu = rr.id_artykulu

-- Ten JOIN łańcuchem sprawdza, czy zalogowany użytkownik
-- jest redaktorem naczelnym czasopisma, do którego
-- przypisany jest ten ARTYKUŁ.
JOIN Czasopismo cz ON a.id_czasopisma = cz.id_czasopisma
JOIN Mapowanie_Uzytkownik_Autor map ON cz.id_redaktora_naczelnego = map.id_autora
WHERE 
    map.nazwa_uzytkownika_db = USER();