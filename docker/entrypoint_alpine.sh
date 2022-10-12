#!/bin/sh
cd /var/www/html
# fix key if needed
if [ -z "$APP_KEY" ]
then
  echo "Please re-run this container with an environment variable \$APP_KEY"
  echo "An example APP_KEY you could use is: "
  php artisan key:generate --show
  exit
fi

#if [ ! -f /var/lib/snipeit/ssl/snipeit-ssl.crt -o ! -f /var/lib/snipeit/ssl/snipeit-ssl.key ]
#then
 # rm /etc/apache2/conf.d/ssl.conf && rm /etc/apache2/conf.d/default-ssl.conf
#fi

# create data directories
for dir in \
  'data/private_uploads' \
  'data/uploads/accessories' \
  'data/uploads/avatars' \
  'data/uploads/barcodes' \
  'data/uploads/categories' \
  'data/uploads/companies' \
  'data/uploads/components' \
  'data/uploads/consumables' \
  'data/uploads/departments' \
  'data/uploads/locations' \
  'data/uploads/manufacturers' \
  'data/uploads/models' \
  'data/uploads/suppliers' \
  'dumps' \
  'keys'
do
  [ ! -d "/var/lib/snipeit/$dir" ] && mkdir -p "/var/lib/snipeit/$dir"
done

chown -R apache:root /var/lib/snipeit/data/*
chown -R apache:root /var/lib/snipeit/dumps
chown -R apache:root /var/lib/snipeit/keys
chown -R apache:root /var/www/html/storage/
chown -R apache:apache /var/www/html

# If the Oauth DB files are not present copy the vendor files over to the db migrations
if [ ! -f "/var/www/html/database/migrations/*create_oauth*" ]
then
  cp -a /var/www/html/vendor/laravel/passport/database/migrations/* /var/www/html/database/migrations/
fi

if [ "${SESSION_DRIVER}" == "database" ]
then
  cp -a /var/www/html/vendor/laravel/framework/src/Illuminate/Session/Console/stubs/database.stub /var/www/html/database/migrations/2021_05_06_0000_create_sessions_table.php
fi

php artisan migrate --force
php artisan config:clear
php artisan config:cache






rm -r "/var/www/html/storage/private_uploads" \
&& mkdir -p "/var/lib/snipeit/data/private_uploads" && ln -fs "/var/lib/snipeit/data/private_uploads" "/var/www/html/storage/private_uploads" \
  && rm -rf "/var/www/html/public/uploads" \
  && mkdir -p "/var/lib/snipeit/data/uploads" && ln -fs "/var/lib/snipeit/data/uploads" "/var/www/html/public/uploads" \
  && mkdir -p "/var/lib/snipeit/dumps" && rm -r "/var/www/html/storage/app/backups" && ln -fs "/var/lib/snipeit/dumps" "/var/www/html/storage/app/backups" \
  && mkdir -p "/var/lib/snipeit/keys" && ln -fs "/var/lib/snipeit/keys/oauth-private.key" "/var/www/html/storage/oauth-private.key" \
  && ln -fs "/var/lib/snipeit/keys/oauth-public.key" "/var/www/html/storage/oauth-public.key" \
  && chown -hR apache "/var/www/html/storage/" \
  && chown -R apache "/var/lib/snipeit"

mkdir -p /var/www/.composer && chown apache /var/www/.composer


if  [ "${APP_ENV}" = "develop" ]; \
then COMPOSER_CACHE_DIR=/dev/null composer install  --working-dir=/var/www/html; \
else COMPOSER_CACHE_DIR=/dev/null composer install  --no-dev --working-dir=/var/www/html; \
fi

chown -R apache:apache /var/www/html

export APACHE_LOG_DIR=/var/log/apache2
exec httpd -DNO_DETACH < /dev/null
