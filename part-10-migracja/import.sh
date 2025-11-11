#!/bin/bash
psql -1 -v ON_ERROR_STOP=1 -U postgres -h localhost -d rims_v2 -f insert_poprawiony_2.sql 