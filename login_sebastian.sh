#!/usr/bin/env bash

# OSTRZEŻENIE: Hasło w tym pliku jest widoczne jako zwykły tekst!
# Używaj tylko na komputerze, do którego NIKT inny nie ma dostępu.

mysql -u asystent_sebastian -pSuperBezpieczneHaslo99! --init-command="SET ROLE RolaAsystenta; USE rpc;"