#!/bin/bash
USER="rpc_admin"
PASS="Silnehaslo123."

echo "=== RAPORT UPRAWNIEŃ UŻYTKOWNIKÓW PROJEKTU ==="

# 1. Pobieramy listę użytkowników i ról związanych z projektem
# Filtrujemy, aby nie pokazywać technicznych użytkowników MySQL (root, mysql.session itp.)
USERS=$(mysql -u $USER -p$PASS -N -B -e "
    SELECT User, Host 
    FROM mysql.user 
    WHERE User NOT IN ('root', 'mysql.session', 'mysql.sys', 'debian-sys-maint') 
    AND User NOT LIKE 'phpmyadmin%'
    ORDER BY User ASC
")

# 2. Iterujemy po każdym użytkowniku i wyświetlamy jego GRANTY
echo "$USERS" | while read u h; do
    if [ -n "$u" ]; then
        echo ""
        echo "👤 UŻYTKOWNIK / ROLA: $u@$h"
        echo "---------------------------------------------------"
        mysql -u $USER -p$PASS -N -e "SHOW GRANTS FOR '$u'@'$h'" 2>/dev/null
    fi
done
