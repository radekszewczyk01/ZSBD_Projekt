USE rpc;

-- RolaRedaktoraNaczelnego
GRANT SELECT ON rpc.Perspektywa_Naczelnego_Poczekalnia TO 'RolaRedaktoraNaczelnego';
GRANT SELECT ON rpc.Perspektywa_Naczelnego_Artykuly_W_Systemie TO 'RolaRedaktoraNaczelnego';
GRANT SELECT ON rpc.Perspektywa_Naczelnego_Moj_Zespol TO 'RolaRedaktoraNaczelnego';
GRANT EXECUTE ON PROCEDURE rpc.sp_Naczelny_PrzypiszRedaktoraDoRundy TO 'RolaRedaktoraNaczelnego';

-- RolaAsystenta
GRANT SELECT ON rpc.Perspektywa_Biblioteka TO 'RolaAsystenta';
GRANT SELECT ON rpc.Perspektywa_Kolejka_Asystenta TO 'RolaAsystenta';
GRANT EXECUTE ON PROCEDURE rpc.sp_Asystent_AkceptujZgloszenie TO 'RolaAsystenta';
GRANT EXECUTE ON PROCEDURE rpc.sp_Redaktor_ZnajdzRecenzentow TO 'RolaAsystenta';
GRANT SELECT ON rpc.Perspektywa_Asystenta_Moje_Rundy TO 'RolaAsystenta';
GRANT EXECUTE ON PROCEDURE rpc.sp_Redaktor_ZaprosRecenzenta TO 'RolaAsystenta';
GRANT EXECUTE ON PROCEDURE rpc.sp_Redaktor_SprawdzStatusyRecenzji TO 'RolaAsystenta';
GRANT EXECUTE ON PROCEDURE rpc.sp_Redaktor_PodejmijDecyzje TO 'RolaAsystenta';

-- RolaRecenzenta (just in case)
GRANT SELECT ON rpc.Perspektywa_Recenzenta_Moje_Zadania TO 'RolaRecenzenta';
GRANT EXECUTE ON PROCEDURE rpc.sp_Recenzent_PrzeslijRecenzje TO 'RolaRecenzenta';

FLUSH PRIVILEGES;
