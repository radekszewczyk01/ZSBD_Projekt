CREATE OR REPLACE VIEW "Perspektywa_Asystenta_Moje_Rundy" AS
SELECT 
    rr.id_rundy,
    rr.id_artykulu,
    a.tytul AS "Tytul_Artykulu",
    rr.numer_rundy,
    ds.nazwa_decyzji AS "Aktualny_Status_Rundy",
    rr.data_rozpoczecia
FROM "RundaRecenzyjna" rr
JOIN "Mapowanie_Uzytkownik_Autor" map 
    ON rr.id_redaktora_prowadzacego = map.id_autora
JOIN "Artykul" a ON rr.id_artykulu = a.id_artykulu
JOIN "Decyzja_Slownik" ds ON rr.id_decyzji = ds.id_decyzji
WHERE 
    map.nazwa_uzytkownika_db = session_user; -- Poprawka: USER() -> session_user

CREATE OR REPLACE VIEW "Perspektywa_Kolejka_Asystenta" AS
SELECT 
    zw.id_zgloszenia,
    zw.tytul,
    zw.status_wstepny,
    cz.tytul AS nazwa_czasopisma,
    zw.data_zgloszenia
FROM "Zgloszenie_Wstepne" zw
JOIN "Czasopismo" cz ON zw.id_czasopisma_docelowego = cz.id_czasopisma
LEFT JOIN "Asystent_Czasopisma" ac ON cz.id_czasopisma = ac.id_czasopisma
LEFT JOIN "Mapowanie_Uzytkownik_Autor" map ON ac.id_asystenta = map.id_autora
WHERE
    (zw.id_przypisanego_asystenta = map.id_autora AND map.nazwa_uzytkownika_db = session_user) -- Poprawka: USER() -> session_user
    OR
    (zw.status_wstepny = 'Oczekuje' AND ac.id_asystenta = map.id_autora AND map.nazwa_uzytkownika_db = session_user); -- Poprawka: USER() -> session_user

CREATE OR REPLACE VIEW "Perspektywa_Autor_Dyscyplina" AS
SELECT 
    d.nazwa AS nazwa_dyscypliny,
    a.imie AS imie_autora,
    a.nazwisko AS nazwisko_autora,
    a.orcid,
    a.id_autora,
    d.id_dyscypliny
FROM 
    "Autor_Dyscyplina" ad
JOIN 
    "Autor" a ON ad.id_autora = a.id_autora
JOIN 
    "Dyscypliny" d ON ad.id_dyscypliny = d.id_dyscypliny;
-- Poprawka: Usunięto 'ORDER BY', które jest niedozwolone w widokach PG

CREATE OR REPLACE VIEW "Perspektywa_Autora_Wszystkie_Czasopisma" AS
SELECT 
    tytul,
    impact_factor,
    czy_otwarty_dostep
FROM 
    "Czasopismo";
-- Poprawka: Usunięto 'ORDER BY', które jest niedozwolone w widokach PG

CREATE OR REPLACE VIEW "Perspektywa_Biblioteka" AS
SELECT 
    a.id_artykulu,
    a.tytul AS tytul_artykulu,
    a.rok_publikacji,
    a.doi,
    cpr.punkty_mein, 
    cz.tytul AS tytul_czasopisma,
    w.nazwa AS wydawca,
    -- Poprawka: GROUP_CONCAT (MySQL) -> string_agg (PostgreSQL)
    string_agg(DISTINCT d.nazwa, ', ') AS dyscypliny
FROM 
    "Artykul" a
JOIN 
    "Czasopismo" cz ON a.id_czasopisma = cz.id_czasopisma
LEFT JOIN 
    "Czasopismo_Punkty_Roczne" cpr 
    ON a.id_czasopisma = cpr.id_czasopisma 
    AND a.rok_publikacji = cpr.rok
LEFT JOIN 
    "Wydawca" w ON cz.id_wydawcy = w.id_wydawcy
LEFT JOIN 
    "Artykul_Dyscyplina" ad ON a.id_artykulu = ad.id_artykulu
LEFT JOIN 
    "Dyscypliny" d ON ad.id_dyscypliny = d.id_dyscypliny
WHERE
    a.id_czasopisma IS NOT NULL
GROUP BY 
    a.id_artykulu,
    cz.id_czasopisma,
    w.id_wydawcy,
    cpr.punkty_mein;

CREATE OR REPLACE VIEW "Perspektywa_Nazwy_Dyscyplin" AS
SELECT nazwa FROM "Dyscypliny";

CREATE OR REPLACE VIEW "Perspektywa_Opublikowane_Artykuly" AS
SELECT 
    a.*
FROM 
    "Artykul" a
WHERE 
    'Zaakceptowany' = (
        SELECT 
            ds.nazwa_decyzji
        FROM 
            "RundaRecenzyjna" rr
        JOIN 
            "Decyzja_Slownik" ds ON rr.id_decyzji = ds.id_decyzji
        WHERE 
            rr.id_artykulu = a.id_artykulu
        ORDER BY 
            rr.numer_rundy DESC
        LIMIT 1
    );

CREATE OR REPLACE VIEW "Perspektywa_Moje_Zgloszenia" AS
SELECT 
    a.id_artykulu,
    a.tytul,
    a.doi,
    rr.numer_rundy,
    ds.nazwa_decyzji AS aktualny_status,
    rr.data_rozpoczecia AS data_rozpoczecia_rundy,
    CONCAT(red_prow.imie, ' ', red_prow.nazwisko) AS redaktor_prowadzacy
FROM 
    "Artykul" a
JOIN 
    "Artykul_Autor" aa ON a.id_artykulu = aa.id_artykulu
JOIN 
    "Mapowanie_Uzytkownik_Autor" map ON aa.id_autora = map.id_autora
JOIN 
    "RundaRecenzyjna" rr ON a.id_artykulu = rr.id_artykulu
LEFT JOIN 
    "Decyzja_Slownik" ds ON rr.id_decyzji = ds.id_decyzji
LEFT JOIN 
    "Autor" red_prow ON rr.id_redaktora_prowadzacego = red_prow.id_autora
WHERE
    a.id_czasopisma IS NULL
    AND map.nazwa_uzytkownika_db = session_user -- Poprawka: USER() -> session_user
    AND rr.numer_rundy = (
        SELECT MAX(rr_inner.numer_rundy) 
        FROM "RundaRecenzyjna" rr_inner 
        WHERE rr_inner.id_artykulu = a.id_artykulu
    );

CREATE OR REPLACE VIEW "Perspektywa_Recenzenta_Moje_Zadania" AS
SELECT 
    rec.id_recenzji,
    a.tytul AS "Tytul_Artykulu",
    cz.tytul AS "Nazwa_Czasopisma",
    rr.numer_rundy
FROM "Recenzja" rec
JOIN "Mapowanie_Uzytkownik_Autor" map 
    ON rec.id_autora_recenzenta = map.id_autora
JOIN "RundaRecenzyjna" rr ON rec.id_rundy = rr.id_rundy
JOIN "Artykul" a ON rr.id_artykulu = a.id_artykulu
JOIN "Czasopismo" cz ON a.id_czasopisma = cz.id_czasopisma
WHERE 
    map.nazwa_uzytkownika_db = session_user -- Poprawka: USER() -> session_user
    AND rec.id_rekomendacji IS NULL;

CREATE OR REPLACE VIEW "Perspektywa_Naczelnego_Moj_Zespol" AS
SELECT 
    a.id_autora,
    a.imie,
    a.nazwisko,
    a.orcid
FROM "Autor" a
JOIN "Asystent_Czasopisma" ac ON a.id_autora = ac.id_asystenta
JOIN "Czasopismo" cz ON ac.id_czasopisma = cz.id_czasopisma
JOIN "Mapowanie_Uzytkownik_Autor" map ON cz.id_redaktora_naczelnego = map.id_autora
WHERE 
    map.nazwa_uzytkownika_db = session_user -- Poprawka: USER() -> session_user
    AND a.id_autora != map.id_autora;

CREATE OR REPLACE VIEW "Perspektywa_Naczelnego_Poczekalnia" AS
SELECT 
    zw.id_zgloszenia,
    zw.tytul,
    zw.status_wstepny,
    zw.data_zgloszenia,
    (SELECT CONCAT(aut.imie, ' ', aut.nazwisko) 
     FROM "Autor" aut 
     WHERE aut.id_autora = zw.id_przypisanego_asystenta) AS "Przypisany Asystent"
FROM "Zgloszenie_Wstepne" zw
JOIN "Czasopismo" cz ON zw.id_czasopisma_docelowego = cz.id_czasopisma
JOIN "Mapowanie_Uzytkownik_Autor" map ON cz.id_redaktora_naczelnego = map.id_autora
WHERE 
    map.nazwa_uzytkownika_db = session_user; -- Poprawka: USER() -> session_user

CREATE OR REPLACE VIEW "Perspektywa_Naczelnego_Artykuly_W_Systemie" AS
SELECT DISTINCT
    a.id_artykulu,
    a.tytul,
    a.doi,
    (SELECT ds.nazwa_decyzji
     FROM "RundaRecenzyjna" rr_sub
     JOIN "Decyzja_Slownik" ds ON rr_sub.id_decyzji = ds.id_decyzji
     WHERE rr_sub.id_artykulu = a.id_artykulu
     ORDER BY rr_sub.numer_rundy DESC
     LIMIT 1) AS "Aktualny_Status",
    (SELECT rr_sub.id_rundy
     FROM "RundaRecenzyjna" rr_sub
     WHERE rr_sub.id_artykulu = a.id_artykulu
     ORDER BY rr_sub.numer_rundy DESC
     LIMIT 1) AS "ID_Ostatniej_Rundy",
    (SELECT rr_sub.id_redaktora_prowadzacego
     FROM "RundaRecenzyjna" rr_sub
     WHERE rr_sub.id_artykulu = a.id_artykulu
     ORDER BY rr_sub.numer_rundy DESC
     LIMIT 1) AS "ID_Redaktora_Prowadzacego"
FROM "Artykul" a
JOIN "RundaRecenzyjna" rr ON a.id_artykulu = rr.id_artykulu
JOIN "Czasopismo" cz ON a.id_czasopisma = cz.id_czasopisma
JOIN "Mapowanie_Uzytkownik_Autor" map ON cz.id_redaktora_naczelnego = map.id_autora
WHERE 
    map.nazwa_uzytkownika_db = session_user; -- Poprawka: USER() -> session_user

CREATE OR REPLACE VIEW "Perspektywa_Redaktora_Prowadzacego" AS
SELECT 
    a.tytul, 
    a.doi, 
    rr.numer_rundy,
    ds.nazwa_decyzji AS status_rundy,
    (SELECT COUNT(*) FROM "Recenzja" r_in WHERE r_in.id_rundy = rr.id_rundy) AS zaproszono,
    (SELECT COUNT(tresc_recenzji) FROM "Recenzja" r_in WHERE r_in.id_rundy = rr.id_rundy) AS otrzymano
FROM "RundaRecenzyjna" rr
JOIN "Artykul" a ON rr.id_artykulu = a.id_artykulu
JOIN "Decyzja_Slownik" ds ON rr.id_decyzji = ds.id_decyzji
WHERE
    -- Poprawka: Poprawiona składnia subquery i nazwy tabel/kolumn
    rr.id_redaktora_prowadzacego = (SELECT id_autora FROM "Mapowanie_Uzytkownik_Autor" WHERE nazwa_uzytkownika_db = session_user)
    AND rr.data_zakonczenia IS NULL;


-- --- Uprawnienia dla "RolaAutora" ---
GRANT SELECT ON "Perspektywa_Opublikowane_Artykuly" TO "RolaAutora";
GRANT SELECT ON "Perspektywa_Moje_Zgloszenia" TO "RolaAutora";
GRANT SELECT ON "Perspektywa_Nazwy_Dyscyplin" TO "RolaAutora";
GRANT SELECT ON "Perspektywa_Recenzenta_Moje_Zadania" TO "RolaAutora";
GRANT SELECT ON "Perspektywa_Autor_Dyscyplina" TO "RolaAutora";
GRANT SELECT ON "Perspektywa_Autora_Wszystkie_Czasopisma" TO "RolaAutora";

-- Nadawanie uprawnień do procedur/funkcji z poprawnymi argumentami
GRANT EXECUTE ON FUNCTION "sp_PobierzMojeSpecjalizacje"() TO "RolaAutora";
GRANT EXECUTE ON FUNCTION "sp_PobierzWszystkieMojeArtykuly"() TO "RolaAutora";
GRANT EXECUTE ON FUNCTION "sp_PobierzAutorowDlaDyscypliny"(character varying) TO "RolaAutora";
GRANT EXECUTE ON PROCEDURE "sp_Autor_ZglosArtykul"(character varying, character varying, integer, integer, text, text) TO "RolaAutora";
GRANT EXECUTE ON PROCEDURE "sp_Autor_Demo_ZglosDoCzasopisma"(character varying) TO "RolaAutora";
GRANT EXECUTE ON PROCEDURE "sp_Autor_Demo_ZglosDoCzasopisma_Poprawne"(character varying) TO "RolaAutora";
GRANT EXECUTE ON PROCEDURE "sp_Recenzent_PrzeslijRecenzje"(integer, character varying, text) TO "RolaAutora";

-- --- Uprawnienia dla "RolaAsystenta" ---
GRANT SELECT ON "Perspektywa_Biblioteka" TO "RolaAsystenta";
GRANT SELECT ON "Perspektywa_Kolejka_Asystenta" TO "RolaAsystenta";
GRANT SELECT ON "Perspektywa_Asystenta_Moje_Rundy" TO "RolaAsystenta";
GRANT SELECT ON "Perspektywa_Redaktora_Prowadzacego" TO "RolaAsystenta"; -- (Dodałem, wydaje się logiczne)

GRANT EXECUTE ON FUNCTION "fn_SprawdzZgodnoscDyscyplin"(integer) TO "RolaAsystenta";
GRANT EXECUTE ON PROCEDURE "sp_Asystent_AkceptujZgloszenie"(integer) TO "RolaAsystenta";
GRANT EXECUTE ON FUNCTION "sp_Redaktor_ZnajdzRecenzentow"(integer) TO "RolaAsystenta";
GRANT EXECUTE ON PROCEDURE "sp_Redaktor_ZaprosRecenzenta"(integer, integer) TO "RolaAsystenta";
GRANT EXECUTE ON FUNCTION "sp_Redaktor_SprawdzStatusyRecenzji"(integer) TO "RolaAsystenta";
GRANT EXECUTE ON PROCEDURE "sp_Redaktor_PodejmijDecyzje"(integer, character varying) TO "RolaAsystenta";

-- --- Uprawnienia dla "RolaRedaktoraNaczelnego" ---
GRANT SELECT ON "Perspektywa_Naczelnego_Poczekalnia" TO "RolaRedaktoraNaczelnego";
GRANT SELECT ON "Perspektywa_Naczelnego_Artykuly_W_Systemie" TO "RolaRedaktoraNaczelnego";
GRANT SELECT ON "Perspektywa_Naczelnego_Moj_Zespol" TO "RolaRedaktoraNaczelnego";

GRANT EXECUTE ON PROCEDURE "sp_Naczelny_PrzypiszRedaktoraDoRundy"(integer, integer) TO "RolaRedaktoraNaczelnego";
