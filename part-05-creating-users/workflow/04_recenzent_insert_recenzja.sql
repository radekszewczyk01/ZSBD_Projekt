-- Uruchamiany przez dr_nowak
-- Wymaga zmiennych: @doi, @id_recenzenta
SET @id_artykulu = (SELECT id_artykulu FROM Artykul WHERE doi = @doi);
SET @id_rundy = (SELECT id_rundy FROM RundaRecenzyjna WHERE id_artykulu = @id_artykulu AND numer_rundy = 1);

INSERT INTO Recenzja (id_rundy, id_autora_recenzenta, id_rekomendacji, tresc_recenzji, data_otrzymania)
VALUES (
    @id_rundy,
    @id_recenzenta, -- Zmienna @id_recenzenta przekazana z BASH
    2, -- (np. 2 = 'Drobne poprawki')
    'Ciekawy artykuł, wymaga jednak kilku drobnych poprawek stylistycznych.',
    CURDATE()
);
SELECT 'Krok 4 (Recenzent): Pomyślnie dodano recenzję.' AS Status;