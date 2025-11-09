-- Krok 1: Stwórz widok (kolejkę), którą będzie widział asystent
-- Ten widok pokazuje zgłoszenia przypisane do asystenta LUB te nieprzypisane
CREATE OR REPLACE VIEW Perspektywa_Kolejka_Asystenta AS
SELECT 
    zw.id_zgloszenia,
    zw.tytul,
    zw.status_wstepny,
    cz.tytul AS nazwa_czasopisma,
    zw.data_zgloszenia
FROM Zgloszenie_Wstepne zw
JOIN Czasopismo cz ON zw.id_czasopisma_docelowego = cz.id_czasopisma
LEFT JOIN Asystent_Czasopisma ac ON cz.id_czasopisma = ac.id_czasopisma
LEFT JOIN Mapowanie_Uzytkownik_Autor map ON ac.id_asystenta = map.id_autora
WHERE
    -- Warunek 1: Pokaż zgłoszenia "W filtracji" przypisane DO MNIE
    (zw.id_przypisanego_asystenta = map.id_autora AND map.nazwa_uzytkownika_db = USER())
    OR
    -- Warunek 2: Pokaż zgłoszenia "Oczekujące", którymi MOGĘ się zająć
    (zw.status_wstepny = 'Oczekuje' AND ac.id_asystenta = map.id_autora AND map.nazwa_uzytkownika_db = USER());

-- Krok 2: Nadaj roli uprawnienia
-- Prawo do patrzenia w swoją kolejkę
-- GRANT SELECT ON rims_v2.Perspektywa_Kolejka_Asystenta TO 'RolaAsystenta';

-- Prawo do akceptowania zgłoszeń (przenoszenia do Artykul)
-- GRANT EXECUTE ON PROCEDURE rims_v2.sp_Asystent_AkceptujZgloszenie TO 'RolaAsystenta';

-- (Opcjonalnie) Prawo do podejmowania i odrzucania (jeśli stworzysz te procedury)
-- GRANT EXECUTE ON PROCEDURE rims_v2.sp_Asystent_PodejmijZgloszenie TO 'RolaAsystenta';
-- GRANT EXECUTE ON PROCEDURE rims_v2.sp_Asystent_OdrzucZgloszenie TO 'RolaAsystenta';