#!/bin/bash

WebConf=/etc/apache2/conf.d/spotweb.conf
SSLWebConf=/etc/apache2/conf.d/spotweb_ssl.conf
WebDir=/var/www/spotweb

echo
echo "Installing Spotweb webfiles from github:"
git init ${WebDir}
cd ${WebDir}
git remote add origin https://github.com/spotweb/spotweb.git

if [[ ! -z ${VERSION} ]]
then
  echo "Downloading Spotweb ${VERSION}:"
  git pull origin ${VERSION}
else
  echo "Downloading Spotweb master"
  git pull origin master
fi

# make sure cache directory exists prior to executing chown -R apache: ${WebDir}
# if cache dir does not exists, it is created by root user on first retrieve and result in a database error

mkdir ${WebDir}/cache

echo

# Create the Retrieve cron entry
if [[ -n "$SPOTWEB_CRON_RETRIEVE" || -n "$SPOTWEB_CRON_CACHE_CHECK" ]]
then
  echo "Scheduling tasks....."
	if [[ -n "$SPOTWEB_CRON_RETRIEVE" ]]; then
    echo "Creating crontab entry for Retrieve with schedule:  $SPOTWEB_CRON_RETRIEVE"
    echo "$SPOTWEB_CRON_RETRIEVE /usr/bin/php /var/www/spotweb/retrieve.php >/var/log/stdout 2>&1" > /etc/crontabs/root
	fi
	if [[ -n "$SPOTWEB_CRON_CACHE_CHECK" ]]; then
    echo "Creating crontab entry for check-cache with schedule:  $SPOTWEB_CRON_CACHE_CHECK"
    echo "$SPOTWEB_CRON_CACHE_CHECK /usr/bin/php /var/www/spotweb/bin/check-cache.php >/var/log/stdout 2>&1" >> /etc/crontabs/apache
	fi
fi

echo

# Create crond service
busybox crond -L /dev/stdout

case ${SSL} in
  enabled)
    echo "Deploying apache config with SSL support:"
    cat <<EOF > ${SSLWebConf}
<VirtualHost 0.0.0.0:443>
    ServerAdmin _

    SSLEngine on
    SSLCertificateFile "/etc/ssl/web/spotweb.crt"
    SSLCertificateKeyFile "/etc/ssl/web/spotweb.key"
    SSLCertificateChainFile "/etc/ssl/web/spotweb.chain.crt"

    DocumentRoot ${WebDir}
    <Directory ${WebDir}/>
        RewriteEngine on
        RewriteCond %{REQUEST_URI} !api/
        RewriteRule ^api/?$ index.php?page=newznabapi [QSA,L]
        Options Indexes FollowSymLinks MultiViews
        AllowOverride All
        Require all granted
    </Directory>
</VirtualHost>
EOF
  chown apache: ${SSLWebConf}
  chmod 600 /etc/ssl/web/*
  apk add apache2-ssl
  ;;

  *)
    echo "Deploying apache config without SSL support:"
esac

cat <<EOF > ${WebConf}
<VirtualHost 0.0.0.0:80>
    ServerAdmin _

    DocumentRoot ${WebDir}
    <Directory ${WebDir}/>
        RewriteEngine on
        RewriteCond %{REQUEST_URI} !api/
        RewriteRule ^api/?$ index.php?page=newznabapi [QSA,L]
        Options Indexes FollowSymLinks MultiViews
        AllowOverride All
        Require all granted
    </Directory>
</VirtualHost>
EOF
chown apache: ${WebConf}
sed -i 's/#LoadModule rewrite_module/LoadModule rewrite_module/g' /etc/apache2/httpd.conf
sed -i "s/#ServerName www.example.com/ServerName $(hostname)/g" /etc/apache2/httpd.conf
echo "date.timezone = ${TZ}" >> /etc/php7/php.ini

echo
echo "Installing ${SQL} support:"
case ${SQL} in
  sqlite)
    apk add php7-pdo_sqlite
  ;;

  psql)
    apk add php7-pgsql php7-pdo_pgsql
  ;;

  mysql)
    apk add php7-mysqlnd php7-pdo_mysql
  ;;

  *)
    echo
    echo "Option SQL=${SQL} invalid, use sqlite, psql or mysql!"
  ;;
esac



if [[ ! -z ${UUID} ]]
then
  echo
  echo "Replacing old apache UID with ${UUID}"
  OldUID=$(getent passwd apache | cut -d ':' -f3)
  usermod -u ${UUID} apache
  find / -user ${OldUID} -exec chown -h apache {} \; &> /dev/null
fi

if [[ ! -z ${GUID} ]]
then
  echo "Replacing old apache GID with ${GUID}"
  OldGID=$(getent passwd apache | cut -d ':' -f4)
  groupmod -g ${GUID} apache
  find / -group ${OldGID} -exec chgrp -h apache {} \; &> /dev/null
fi

chown -R apache: ${WebDir}
rm -rf /var/cache/apk/* && \

echo "Deployment done!"
echo
# run command with exec to pass control
echo "Running CMD: $@"
exec "$@"
