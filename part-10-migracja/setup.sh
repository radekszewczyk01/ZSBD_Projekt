#!/bin/bash

# ustawienie lokalizacji na polską
sudo locale-gen pl_PL.UTF-8
sudo update-locale

# sprawdznie
locale -a | grep pl_PL.utf8

# zalogowanie do postgres
sudo -u postgres psql

# wykonanie polecenia w psql z pliku tworzenie_nowej_bazy.sql

