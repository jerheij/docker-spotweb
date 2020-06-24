[![](https://images.microbadger.com/badges/version/jerheij/spotweb:stable.svg)](https://microbadger.com/images/jerheij/spotweb:stable "Get your own version badge on microbadger.com") [![](https://images.microbadger.com/badges/commit/jerheij/spotweb:stable.svg)](https://microbadger.com/images/jerheij/spotweb:stable "Get your own commit badge on microbadger.com") [![](https://images.microbadger.com/badges/image/jerheij/spotweb:stable.svg)](https://microbadger.com/images/jerheij/spotweb:stable "Get your own image badge on microbadger.com")  

## Spotweb container

### Sources
Base image: [Alpine:latest](https://hub.docker.com/_/alpine/)
Main software: [Spotweb](https://github.com/spotweb/spotweb)
Packages: php7, openssl, apache2


### Requirements
You need a separate database server (both MySQL/MariaDB and PostgreSQL are supported through my config) or you can use SQLite within the container.

### Usage

#### Supported modes
You can connect to the container with or without SSL You can also connect a reverse proxy to the exposed port and setup any sort of connection from there.

#### Initial installation
When you run the docker image for the first time without optional parameters it will download the master Spotweb branch into the webfolder and install the chosen php7 SQL module.
```
docker run --restart=always -d -p 80:80 \
		--hostname=spotweb \
		--name=spotweb \
		-e TZ='Europe/Amsterdam' \
		-e SQL='mysql'
		jerheij/spotweb
```
After this browse to the exposed port and add "install.php" to it to run the configuration wizard.

#### Permanent version
To make the installation permanent (surviving an upgrade) you need to secure the /var/www/spotweb/dbsettings.inc.php configuration. The best way is to copy that file to your config folder and make a manual mapping:

```
docker run --restart=always -d -p 80:80 \
		--hostname=spotweb \
		--name=spotweb \
		-v <location_dbsettings.inc.php>:/var/www/spotweb/dbsettings.inc.php \
		-e TZ='Europe/Amsterdam' \
		-e SQL='mysql'
		jerheij/spotweb
```
The run command will keep the container "permanent".

#### Docker compose example
The following docker-compose.yml example correspondents to the above:
```
services:
  spotweb:
    image: jerheij/spotweb:latest
    container_name: spotweb
    restart: always
    ports:
      - "192.168.1.1:80:80"
    environment:
      TZ: Europe/Amsterdam
      SQL: mysql
    volumes:
      - config/dbsettings_spotweb.php:/var/www/spotweb/dbsettings.inc.php
```
### SSL
This will enable the SSL modules and configuration in Apache2 and deploy an Apache2 SSL configuration on port 443. It expects the following files to be available:
- /etc/ssl/web/spotweb.crt
- /etc/ssl/web/spotweb.key
- /etc/ssl/web/spotweb.chain.crt

Suggested method is to mount a local directory with those certificates to /etc/ssl/webfolder:
```
...
volumes:
  - ssl:/etc/ssl/web:ro
```

### Variables
| Variable | Function | Optional |
| --- | --- | --- |
| `TZ` | Timezone for PHP configuration | no |
| `SQL`| SQL type for Spotweb (sqlite, psql or mysql) | no |
| `SSL`| Enable or disable SSL support in apache (enabled/disabled) | yes|
|`UUID`| UID of the apache user, for mount and persistence compatibility | yes |
|`GUID`| GID of the apache group, for mount and persistence compatibility| yes |
|`VERSION`| Spotweb version, defaults to master branch but you can use a version tag from their [git](https://github.com/spotweb/spotweb) page | yes |

### Changes
I have introduced a "stable" tag instead of the "latest". The "latest" tag will be the git "master" branch while the "stable" tag will be the latest git tag.

For changes in the different versions see my [github](https://github.com/jerheij/docker-spotweb) repo's commit messages.

### Author
Jerheij
