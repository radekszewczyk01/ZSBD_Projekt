-- Uruchamiany przez redaktor_kowalski
-- Wymaga zmiennej: @doi
SET @id_artykulu = (SELECT id_artykulu FROM Artykul WHERE doi = @doi);
SET @id_rundy = (SELECT id_rundy FROM RundaRecenzyjna WHERE id_artykulu = @id_artykulu AND numer_rundy = 1);

-- Ustawienie decyzji na 'Zaakceptowany' (np. id_decyzji = 1)
UPDATE RundaRecenzyjna
SET 
    id_decyzji = 1, 
    data_zakonczenia = CURDATE()
WHERE id_rundy = @id_rundy;

-- Odebranie uprawnień
REVOKE SELECT ON rpc.RundaRecenzyjna FROM 'RolaRecenzenta';

SELECT 'Krok 5 (Redaktor): Runda zaakceptowana. Odebrano uprawnienia recenzentom.' AS Status;