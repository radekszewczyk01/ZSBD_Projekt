mysqldump -u root -p --routines --events --triggers rims_v2 > rims_v2_backup_pelna.sql
mysqldump -u root -p mysql > rims_v2_backup_UZYTKOWNICY.sql

CREATE DATABASE rims_v2_TEST;
mysql -u root -p rims_v2_TEST < rims_v2_backup_pelna.sql