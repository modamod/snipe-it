#!/bin/bash
#
# SPDX-License-Identifier: MIT
# Copyright © 2022 Modamod
#
# startup.sh
# Description:
# Initializes the database and starts the snipeit app.
#
# Notes:
# Rerunning this script will update the db password for snipeit user with random passowrd each time.
#
install_aws_cli(){
    sudo apt-get update
    sudo apt-get install -y awscli
}
get_dump_from_s3() {
    echo "s3://$1/$2" $3
    aws s3 cp "s3://$1/$2" $3
    return $?
}

restore_database() {
    mysql -u $1 -p$2 $3 < $4
}



: ${OUTPUT="$GITPOD_REPO_ROOT/.gp/data/dump.sql"}
install_aws_cli
mysqluserpw="$(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c16; echo)"
mysql -u root -e "CREATE USER IF NOT EXISTS 'snipeit'@'localhost';"
mysql -u root -e "ALTER USER 'snipeit'@'localhost' IDENTIFIED BY '${mysqluserpw}';"
mysql -u root -e "CREATE DATABASE IF NOT EXISTS snipeit;GRANT ALL PRIVILEGES ON snipeit.* TO 'snipeit'@'localhost'; FLUSH PRIVILEGES;"
if [[ ! $(mysql -u root -e "SELECT 1 FROM users LIMIT 1;" snipeit) ]]; then
    echo "RESTORING"
    restore_database "snipeit" $mysqluserpw "snipeit" $OUTPUT
fi
cp -f .env.gitpod.example .env
sed -i "s|^\\(DB_PASSWORD=\\).*|\\1'${mysqluserpw}'|" .env
sed -i "s|APP_URL=|APP_URL=${GITPOD_WORKSPACE_URL}|g" .env
sed -i "s|APP_URL=https://|APP_URL=https://8000-|g" .env
docker-compose up -d --build
gp await-port 3306
mysqluserpw="$(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c16; echo)"
mysql -u root -e "CREATE USER IF NOT EXISTS 'snipeit'@'localhost';"
mysql -u root -e "ALTER USER 'snipeit'@'localhost' IDENTIFIED BY '${mysqluserpw}';"
mysql -u root -e "CREATE DATABASE IF NOT EXISTS snipeit;GRANT ALL PRIVILEGES ON snipeit.* TO 'snipeit'@'localhost'; FLUSH PRIVILEGES;"
if [[ ! $(mysql -u root -e "SELECT 1 FROM users LIMIT 1;" snipeit) ]]; then
    echo "RESTORING"
    restore_database "snipeit" $mysqluserpw "snipeit" $OUTPUT
fi
# composer install
# php artisan migrate --force
# php artisan key:generate
# nginx && /usr/sbin/php-fpm7.4 --fpm-config .gp/config/fpm.conf
