### PART 01 Loading Data

## Problemy i rozwiązania (skrót)

- LOCAL INFILE wyłączone: błąd „Loading local data is disabled; this must be enabled on both the client and server sides”.
	- Rozwiązanie: serwer `local_infile=1` (SET GLOBAL/PERSIST lub w my.cnf + restart), klient: mysql CLI z `--local-infile=1`.

- Klient Node (v2.0) wymaga `streamFactory`/`infileStreamFactory` (ReadStream) dla `LOAD DATA LOCAL INFILE`.
	- Rozwiązanie: użyto mysql CLI (nie wymaga streamFactory).
