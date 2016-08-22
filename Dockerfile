
# Use Ubuntu 14.04 Trusty
FROM ubuntu:trusty

# Avoid interactive problems when using apt-get
ENV DEBIAN_FRONTEND noninteractive

# Enable multiverse repository
RUN echo "deb http://archive.ubuntu.com/ubuntu/ trusty main universe multiverse" > /etc/apt/sources.list
RUN echo "deb http://archive.ubuntu.com/ubuntu/ trusty-updates main universe multiverse" >> /etc/apt/sources.list

# Install required packages
RUN apt-get -qq update && \
    apt-get install -qq -y \
    php5-cgi php5-cli php5-common php5-dev php5-fpm \
    php5-curl php5-gd php5-json php5-mysql php5-readline \
    apache2-mpm-worker libapache2-mod-fastcgi \
    pkg-config make gcc autoconf git vim mysql-client curl \
    && rm -rf /var/lib/apt/lists/*

# Copy PHP setting files
COPY config/php/php.ini /etc/php5/fpm/php.ini
COPY config/php/opcache.ini /etc/php5/mods-available/opcache.ini
COPY config/php/www.conf /etc/php5/fpm/pool.d/www.conf

# Install Drush
RUN php -r "readfile('https://s3.amazonaws.com/files.drush.org/drush.phar');" > /usr/local/bin/drush && chmod +x /usr/local/bin/drush

# Copy Apache2 settings
COPY config/apache2/virtualhost.conf /etc/apache2/sites-available/drupal.conf
COPY config/apache2/php5-fpm.conf /etc/apache2/conf-available/php5-fpm.conf

# Ensure mod rewrite and virtualhost is enabled
RUN a2enmod rewrite actions fastcgi alias
RUN a2enconf php5-fpm
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
