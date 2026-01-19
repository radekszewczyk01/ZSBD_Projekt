#!/usr/bin/env bash

# OSTRZEŻENIE: Hasło w tym pliku jest widoczne jako zwykły tekst!
# Używaj tylko na komputerze, do którego NIKT inny nie ma dostępu.

mysql -u author_lukasz_1 -pSilneHasloOlaf123! --init-command="SET ROLE RolaAutora; USE rpc;"