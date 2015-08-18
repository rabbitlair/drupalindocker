# Simple script to have local env up and running

# Container settings
NAME=drupal
URL=local.drupal.es
PORT=8080

# Drupal settings
ADMINPASS=password
SITENAME=My Dev Site
VERSION=7.x
PROFILE=standard

# Database settings
DBNAME=dbname
DBUSER=dbuser
DBPASS=dbpass
MYSQL_ROOT_PASSWORD=root

all: docker

docker:
	@docker pull mysql
	@docker pull memcached
	@docker run --name mysql -e MYSQL_ROOT_PASSWORD=${MYSQL_ROOT_PASSWORD} \
    -e MYSQL_DATABASE=${DBNAME} -e MYSQL_USER=${DBUSER} -e MYSQL_PASSWORD=${DBPASS} -d mysql
	@docker run --name memcached -d memcached
	@docker build -t ${NAME} .
	@docker run -d -p ${PORT}:80 -v $(shell pwd):/var/www/drupal \
    --link mysql:mysql --link memcached:memcached --name=${NAME} ${NAME}
	@echo "127.0.0.1 ${URL}" | sudo tee --append /etc/hosts > /dev/null
	@docker logs -f ${NAME}

customize:
	@echo "export TERM=xterm" >> ~/.bashrc
	@cp config/vimrc /root/.vimrc
	@git config --global alias.st status
	@git config --global color.ui true
	@sleep 10 # TODO Wait for MySQL to be up in a proper way

install:
	@drush dl drupal-${VERSION} --yes --drupal-project-rename=docroot
	@mkdir -p docroot/sites/all/modules/contrib
	@mkdir docroot/sites/default/files && chmod 0644 docroot/sites/default/files
	@drush si ${PROFILE} -y --db-url=mysql://${DBUSER}:${DBPASS}@mysql/${DBNAME} \
    --account-pass="${ADMINPASS}" --root=/var/www/drupal/docroot --site-name="${SITENAME}" \
    install_configure_form.update_status_module='array(FALSE,FALSE)'
	@chown -R www-data:www-data docroot/sites/default/files

memcache:
	@drush dl memcache --destination=sites/all/modules/contrib --root=/var/www/drupal/docroot
	@cat config/drupal/memcache-settings-${VERSION} >> docroot/sites/default/settings.php
	@drush -y en memcache --root=/var/www/drupal/docroot --uri=${URL}

configure:
	@sed -i 's/SERVER_NAME/${URL}/g' /etc/apache2/sites-available/drupal.conf
	@echo "ServerName docker" >> /etc/apache2/apache2.conf
	@drush uli --root=/var/www/drupal/docroot --uri=${URL}:${PORT}

drupal: customize install memcache configure
	@service php5-fpm restart
	@service apache2 restart
	@touch /var/log/apache2/error.log
	@touch /var/log/php_errors.log
	@nohup tail -f /var/log/php_errors.log > /dev/stderr &
	@tail -f /var/log/apache2/error.log

clean:
	@docker kill ${NAME} 2>&1 && docker rm ${NAME} 2>&1
	@docker kill mysql 2>&1  && docker rm mysql 2>&1
	@docker kill memcached 2>&1  && docker rm memcached 2>&1
	@sudo chown -R $(shell id -u -n):$(shell id -g -n) docroot
	@sudo sed -i '/127.0.0.1 ${URL}/d' /etc/hosts

clean-all: clean
	@sudo rm -rf docroot

