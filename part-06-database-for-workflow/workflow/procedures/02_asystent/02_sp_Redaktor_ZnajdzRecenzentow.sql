/*--- WYKONAJ JAKO ADMINISTRATOR ---*/
USE rims_v2;
DROP PROCEDURE IF EXISTS sp_Redaktor_ZnajdzRecenzentow;

DELIMITER $$
CREATE PROCEDURE sp_Redaktor_ZnajdzRecenzentow(
    IN p_id_artykulu INT
)
BEGIN
    -- --- BLOK ZABEZPIECZAJĄCY ---
    DECLARE v_id_asystenta INT;
    DECLARE v_id_czasopisma_artykulu INT;
    DECLARE v_ma_dostep BOOLEAN DEFAULT FALSE;

    -- Krok 1: Znajdź ID zalogowanego asystenta
    SELECT id_autora INTO v_id_asystenta
    FROM Mapowanie_Uzytkownik_Autor
    WHERE nazwa_uzytkownika_db = USER() LIMIT 1;

    -- Krok 2: Znajdź, do jakiego czasopisma należy artykuł
    SELECT id_czasopisma INTO v_id_czasopisma_artykulu
    FROM Artykul
    WHERE id_artykulu = p_id_artykulu;
    
    IF v_id_czasopisma_artykulu IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Błąd: Artykuł nie został znaleziony lub nie jest przypisany do żadnego czasopisma.';
    END IF;

    -- Krok 3: Sprawdź, czy ten asystent ma dostęp do tego czasopisma
    SELECT EXISTS (
        SELECT 1
        FROM Asystent_Czasopisma
        WHERE id_asystenta = v_id_asystenta
          AND id_czasopisma = v_id_czasopisma_artykulu
    ) INTO v_ma_dostep;

    -- Krok 4: Jeśli nie ma dostępu, przerwij
    IF v_ma_dostep = FALSE THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Błąd: Nie masz uprawnień do zarządzania artykułami tego czasopisma.';
    END IF;
    -- --- KONIEC BLOKU ZABEZPIECZAJĄCEGO ---


    -- Krok 5: (Oryginalna logika) Pokaż autorów, którzy nie są autorami tego artykułu
    SELECT DISTINCT
        a.id_autora,
        a.imie,
        a.nazwisko,
        a.orcid,
        d.nazwa_dyscypliny AS 'Pasujaca_Dyscyplina'
    FROM Autor a
    -- Znajdź ich dyscypliny
    JOIN Autor_Dyscyplina ad ON a.id_autora = ad.id_autora
    -- Połącz z dyscyplinami artykułu
    JOIN Artykul_Dyscyplina art_d ON ad.id_dyscypliny = art_d.id_dyscypliny
    JOIN Dyscypliny d ON ad.id_dyscypliny = d.id_dyscypliny
    WHERE
        -- Artykuł musi pasować
        art_d.id_artykulu = p_id_artykulu
        -- Autor nie może być na liście autorów artykułu
        AND a.id_autora NOT IN (
            SELECT id_autora FROM Artykul_Autor WHERE id_artykulu = p_id_artykulu
        );
END$$
DELIMITER ;

-- Nadaj uprawnienia Redaktorom (RolaAsystenta) - to polecenie jest OK