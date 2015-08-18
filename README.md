## Drupal in Docker

Simple set of scripts to launch a new Drupal local site on Docker containers. It deploys an Ubuntu 14.04 webserver node inside a Docker container, with Apache 2.4 and PHP FPM 5.5, with some PHP extensions already configured: memcached, opecache and igbinary.

Drush is installed from PEAR channel, and Drupal 6 and 7 are supported (both are installed with Memcache support enabled). MySQL and Memcached official Docker images are used to run those services. WARNING: database is not persistent when you destroy the container, so save your work if you want to reuse it.

### Usage

First, edit Makefile, and set your preferred settings:

- *NAME:* name of the Docker container
- *URI:* domain to be used by the Drupal site
- *PORT:* you localhost port which will be redirected to the container's tcp/80
- *ADMINPASS:* password for Drupal's admin account
- *SITENAME:* site title for the website
- *VERSION:* Choose between 6.x and 7.x
- *PROFILE:* Name of the profile to be installed - default for 6.x, standard for 7.x
- *DBNAME:* Database name where Drupal will be installed
- *DBUSER:* Database user for the Drupal app
- *DBPASS:* Database user's password
- *MYSQL_ROOT_PASSWORD:* Password for database's root account

After that, save the changes, and execute `make` to have everything up and running. First execution will take longer, as it has to pull and build the Docker images.

To kill and remove the containers, but not delete the Drupal code, execute `make clean`. If you want to clean containers and the Drupal code, execute `make clean-all`.

### Dependencies

This has been tested on Ubuntu 14.04 64 bits. Anyway, you should only need to have installed latest `make` and `docker` packages from your distribution package manager.

