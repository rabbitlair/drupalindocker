# Simple script to have local env up and running

# Container settings
NAME=drupal
URL=local.drupal.es
PORT=8080

# Drupal settings
ADMINMAIL=admin@example.com
ADMINPASS=password
SITENAME=My Dev Site

# Database settings
DBNAME=dbname
DBUSER=dbuser
DBPASS=dbpass
ROOTPASS=root

# Bash snippet to check if MySQL server is up
MYSQL_CHECK=mysql -uroot -p$(ROOTPASS) -hmysql -sN -e "SELECT 1"  2> /dev/null || echo "0"

# Check docker images are ready to be used
BASEIMAGE=$(shell docker images | grep ${NAME} | wc -l)
MYSQLIMAGE=$(shell docker images | grep mysql | wc -l)
MEMCACHEIMAGE=$(shell docker images | grep memcached | wc -l)

all: docker

docker:
	@[ "$(MYSQLIMAGE)" -eq "1" ] || docker pull mysql
	@[ "$(MEMCACHEIMAGE)" -eq "1" ] || docker pull memcached
	@[ "$(BASEIMAGE)" -eq "1" ] || docker build -t ${NAME} .
	@[ -d "mysql-data" ] || mkdir mysql-data
	@docker run --name mysql -v $(shell pwd)/mysql-data:/var/lib/mysql \
    -e MYSQL_ROOT_PASSWORD=${ROOTPASS} -e MYSQL_DATABASE=${DBNAME} -e MYSQL_USER=${DBUSER} \
    -e MYSQL_PASSWORD=${DBPASS} -d mysql
	@docker run --name memcached -d memcached
	@docker run -d -p ${PORT}:80 -v $(shell pwd):/var/www/drupal \
    --link mysql:mysql --link memcached:memcached --name=${NAME} ${NAME}
	@echo "127.0.0.1 ${URL}" | sudo tee --append /etc/hosts > /dev/null
	@docker logs -f ${NAME}

customize:
	@echo "export TERM=xterm" >> ~/.bashrc
	@cp config/vimrc /root/.vimrc
	@git config --global alias.st status
	@git config --global color.ui true
	@while [ `$(MYSQL_CHECK)` != "1" ]; do sleep 1; done

configure:
	@echo 'export PATH="$$HOME/.composer/vendor/bin:$$PATH"' >> /root/.bashrc
	@sed -i 's/SERVER_NAME/${URL}/g' /etc/apache2/sites-available/drupal.conf
	@echo "ServerName docker" >> /etc/apache2/apache2.conf

install:
ifneq ($(wildcard ./docroot/.*),)
	@chown -R www-data:www-data docroot/sites/default/files
else
	@drush dl drupal-7.x --yes --drupal-project-rename=docroot
	@mkdir -p docroot/sites/all/modules/contrib
	@mkdir docroot/sites/default/files && chmod 0644 docroot/sites/default/files
	@drush si standard -y \
    --db-url=mysql://${DBUSER}:${DBPASS}@mysql/${DBNAME} --root=/var/www/drupal/docroot \
    --account-pass="${ADMINPASS}" --account-mail="${ADMINMAIL}" --site-name="${SITENAME}" \
    install_configure_form.update_status_module='array(FALSE,FALSE)'
	@drush dl memcache --destination=sites/all/modules/contrib --root=/var/www/drupal/docroot
	@cat config/drupal/memcache-settings >> docroot/sites/default/settings.php
	@drush -y en memcache --root=/var/www/drupal/docroot
endif

drupal: customize configure install
	@drush uli --root=/var/www/drupal/docroot --uri=${URL}:${PORT}
	@service php5-fpm restart
	@service apache2 restart
	@touch /var/log/apache2/error.log
	@touch /var/log/php_errors.log
	@nohup tail -f /var/log/php_errors.log > /dev/stderr &
	@tail -f /var/log/apache2/error.log

start:
	@docker start mysql
	@docker start memcached
	@docker start ${NAME}

stop:
	@docker stop ${NAME}
	@docker stop mysql
	@docker stop memcached

halt:
	@-docker kill ${NAME} 2>&1
	@-docker rm ${NAME} 2>&1
	@-docker kill mysql 2>&1
	@-docker rm mysql 2>&1
	@-docker kill memcached 2>&1
	@-docker rm memcached 2>&1
	@sudo chown -R $(shell id -u -n):$(shell id -g -n) docroot mysql-data
	@sudo sed -i '/127.0.0.1 ${URL}/d' /etc/hosts

destroy: halt
	@sudo rm -rf mysql-data docroot

