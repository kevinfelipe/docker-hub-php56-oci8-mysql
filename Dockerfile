FROM php:5.6-apache

RUN apt-get update && apt-get install -y libzip-dev
RUN docker-php-ext-install zip

RUN apt-get update && apt-get install -y \
        libfreetype6-dev \
        libjpeg62-turbo-dev \
        libpng-dev \
    && docker-php-ext-configure gd --with-freetype --with-jpeg-dir \
    && docker-php-ext-install -j$(nproc) gd
        
RUN apt-get update -y \
 && apt-get install -y libcurl4-openssl-dev pkg-config libssl-dev vim


RUN apt-get update && \
    apt-get install -y apt-utils freetds-dev sendmail libpng-dev zlib1g-dev

# zip, socket, mbstring
RUN docker-php-ext-install zip sockets 
RUN  apt-get update && apt-get install -y zip

RUN apt-get update

RUN apt-get install -y libpq-dev \
    && docker-php-ext-configure pgsql -with-pgsql=/usr/local/pgsql \
    && docker-php-ext-install pdo pdo_pgsql pgsql



#mssql
RUN apt-get update && apt-get install -y gnupg2
ENV ACCEPT_EULA=Y
ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get install -y libaio1
RUN apt-get install -y unixodbc 

RUN docker-php-ext-install pdo pdo_mysql 
RUN docker-php-ext-configure pdo_dblib --with-libdir=/lib/x86_64-linux-gnu

RUN docker-php-ext-install pdo_dblib
    


# RUN docker-php-ext-install pdo_dblib
RUN docker-php-ext-install zip

# Install XDebug - Required for code coverage in PHPUnit
#RUN yes | pecl install xdebug \
#    && echo "zend_extension=$(find /usr/local/lib/php/extensions/ -name xdebug.so)" > /usr/local/etc/php/conf.d/xdebug.ini \
#    && echo "xdebug.remote_enable=on" >> /usr/local/etc/php/conf.d/xdebug.ini \
#    && echo "xdebug.remote_autostart=off" >> /usr/local/etc/php/conf.d/xdebug.ini

# Copy over the php conf
COPY docker-conf/docker-php.conf /etc/apache2/conf-enabled/docker-php.conf

# Copy over the php ini
COPY docker-conf/docker-php.ini $PHP_INI_DIR/conf.d/

# Set the timezone
ENV TZ=America/America/Sao_Paulo
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

RUN printf "log_errors = On \nerror_log = /dev/stderr\n" > /usr/local/etc/php/conf.d/php-logs.ini


# Configure LDAP.
RUN apt-get update \
 && apt-get install libldap2-dev -y \
 && rm -rf /var/lib/apt/lists/* \
 && docker-php-ext-configure ldap --with-libdir=lib/x86_64-linux-gnu/ \
 && docker-php-ext-install ldap



# Enable mod_rewrite
RUN a2enmod rewrite

# Install Oracle instantclient
RUN mkdir /opt/oracle \
    && curl 'https://download.oracle.com/otn_software/linux/instantclient/19600/instantclient-basic-linux.x64-19.6.0.0.0dbru.zip' --output /opt/oracle/instantclient-basic-linux.zip \
    && curl 'https://download.oracle.com/otn_software/linux/instantclient/19600/instantclient-sdk-linux.x64-19.6.0.0.0dbru.zip' --output /opt/oracle/instantclient-sdk-linux.zip \
    && unzip '/opt/oracle/instantclient-basic-linux.zip' -d /opt/oracle \
    && unzip '/opt/oracle/instantclient-sdk-linux.zip' -d /opt/oracle \
    && rm /opt/oracle/instantclient-*.zip \
    && mv /opt/oracle/instantclient_* /opt/oracle/instantclient \
    && docker-php-ext-configure oci8 --with-oci8=instantclient,/opt/oracle/instantclient \
    && docker-php-ext-install oci8 \
    && echo /opt/oracle/instantclient/ > /etc/ld.so.conf.d/oracle-insantclient.conf \
    && ldconfig
#RUN pecl install PDO_DBLIB

# Install Composer
ENV COMPOSER_HOME /composer
ENV PATH ./vendor/bin:/composer/vendor/bin:$PATH
ENV COMPOSER_ALLOW_SUPERUSER 1
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer
RUN composer --version

# Add the files and set permissions
WORKDIR /var/www/html
ADD ./ /var/www/html

RUN chown -R www-data:www-data /var/www/html
EXPOSE 80