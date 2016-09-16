
# Use Ubuntu 14.04 Trusty
FROM ubuntu:trusty

# Avoid interactive problems when using apt-get
ENV DEBIAN_FRONTEND noninteractive

# Enable multiverse repository
RUN echo "deb http://archive.ubuntu.com/ubuntu/ trusty main universe multiverse" > /etc/apt/sources.list
RUN echo "deb http://archive.ubuntu.com/ubuntu/ trusty-updates main universe multiverse" >> /etc/apt/sources.list

# Add PPA for PHP 7.0 install
RUN apt-get -qq update && \
    apt-get install -qq -y \
    software-properties-common python-software-properties language-pack-en-base \
    && rm -rf /var/lib/apt/lists/*
RUN LC_ALL=en_US.UTF-8 add-apt-repository ppa:ondrej/php

# Install required packages
RUN apt-get -qq update && \
    apt-get install -qq -y \
    php7.0 php7.0-cgi php7.0-cli php7.0-fpm php7.0-gd php7.0-json php7.0-mysql \
    php7.0-curl php7.0-readline php7.0-mbstring php7.0-zip php7.0-xml php-xdebug \
    apache2-mpm-worker libapache2-mod-fastcgi \
    pkg-config make gcc autoconf git vim mysql-client curl postfix \
    && rm -rf /var/lib/apt/lists/*

# Copy PHP setting files
COPY config/php/php.ini /etc/php/7.0/fpm/php.ini
COPY config/php/www.conf /etc/php/7.0/fpm/pool.d/www.conf
COPY config/php/xdebug.ini /etc/php/7.0/mods-available/xdebug.ini
COPY config/php/opcache.ini /etc/php/7.0/mods-available/opcache.ini
COPY config/vim /root/.vim

# Install Drush
RUN php -r "readfile('https://s3.amazonaws.com/files.drush.org/drush.phar');" > /usr/local/bin/drush && chmod +x /usr/local/bin/drush && mkdir /etc/drush
COPY config/drupal/drush.local.php /etc/drush/project.aliases.drushrc.php

# Copy Apache2 settings
COPY config/apache2/virtualhost.conf /etc/apache2/sites-available/drupal.conf
COPY config/apache2/php7-fpm.conf /etc/apache2/conf-available/php7-fpm.conf

# Ensure mod rewrite and virtualhost is enabled
RUN a2enmod rewrite actions fastcgi alias
RUN a2enconf php7-fpm
RUN a2ensite drupal.conf

# Set needed Apache variables
ENV APACHE_RUN_USER www-data
ENV APACHE_RUN_GROUP www-data
ENV APACHE_RUN_DIR /var/run/apache2
ENV APACHE_LOCK_DIR /var/lock/apache2
ENV APACHE_LOG_DIR /var/log/apache2
ENV APACHE_PID_FILE /var/run/apache2.pid

# Initialization section
EXPOSE 80
WORKDIR /var/www/drupal
ENTRYPOINT ["/usr/bin/make", "drupal"]
