FROM ubuntu:18.04

LABEL maintainer="Diego Mengarda <diegormengarda@gmail.com>"

ARG DEBIAN_FRONTEND=noninteractive
ARG TZ=America/Sao_Paulo

ENV USER=appuser \
    USER_ID=1000 \
    USER_GID=1000 \
    APPDIR=/var/www/app \
    COMPOSER_ALLOW_SUPERUSER=1 \
    COMPOSER_PROCESS_TIMEOUT=900

RUN groupadd --gid "${USER_GID}" "${USER}" && \
    useradd --uid ${USER_ID} --gid ${USER_GID} --create-home --shell /bin/bash ${USER} && \
    apt-get update && \
    apt-get install -y --no-install-recommends ca-certificates apt-utils tzdata locales software-properties-common \
    nano vim curl wget git zip unzip mysql-client postgresql-client openssh-client poppler-utils && \
    echo $TZ > /etc/timezone && \
    rm /etc/localtime && ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && \
    dpkg-reconfigure tzdata && \
    localedef -i pt_BR -c -f UTF-8 -A /usr/share/locale/locale.alias pt_BR.UTF-8

ENV LANG=pt_BR.utf8

RUN add-apt-repository ppa:ondrej/php && \
    apt-get update && \
    apt-get install -y nginx php7.4-cli php7.4-fpm \
    php7.4-common \
    php7.4-curl \
    php7.4-dev \
    php7.4-gd \
    php7.4-gmp \ 
    php7.4-intl \
    php7.4-json \
    php7.4-ldap \
    php7.4-mbstring \
    php7.4-mysql \
    php7.4-pgsql \
    php7.4-soap \
    php7.4-xml \
    php7.4-xmlrpc \
    php7.4-xsl \
    php7.4-zip \
    php7.4-sqlite \
    php-apcu \
    php-pear && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* && \
    rm /etc/nginx/sites-enabled/default && \
    curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

COPY app.conf /etc/nginx/sites-enabled/app
COPY nginx.conf /etc/nginx/nginx.conf

COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint
COPY start.sh /usr/local/bin/start

RUN sed -i "s|;*max_execution_time =.*|max_execution_time = 150|i" /etc/php/7.4/fpm/php.ini && \
    sed -i "s|;*memory_limit =.*|memory_limit = 256M|i" /etc/php/7.4/fpm/php.ini && \
    sed -i "s|;*post_max_size =.*|post_max_size = 128M|i" /etc/php/7.4/fpm/php.ini && \
    sed -i "s|;*upload_max_filesize =.*|upload_max_filesize = 64M|i" /etc/php/7.4/fpm/php.ini && \
    sed -i "s|;*display_errors =.*|display_errors = On|i" /etc/php/7.4/fpm/php.ini && \
    sed -i "s|;*error_reporting =.*|error_reporting = E_ALL|i" /etc/php/7.4/fpm/php.ini && \
    sed -i "s|;*date.timezone =.*|date.timezone = America/Sao_Paulo|i" /etc/php/7.4/fpm/php.ini && \
    sed -i "s|;*cgi.fix_pathinfo.*=.*|cgi.fix_pathinfo = 0|i" /etc/php/7.4/fpm/php.ini && \
    sed -i -e "s/pid =.*/pid = \/var\/run\/php-fpm7.4.pid/" /etc/php/7.4/fpm/php-fpm.conf && \
    sed -i -e "s/error_log =.*/error_log = \/dev\/stderr/" /etc/php/7.4/fpm/php-fpm.conf && \
    sed -i -e "s/;daemonize\s*=\s*yes/daemonize = no/g" /etc/php/7.4/fpm/php-fpm.conf && \
    sed -i "s/user = .*/user = ${USER}/" /etc/php/7.4/fpm/pool.d/www.conf && \
    sed -i "s/group = .*/group = ${USER}/" /etc/php/7.4/fpm/pool.d/www.conf && \
    sed -i "s/listen = .*/listen = 9000/" /etc/php/7.4/fpm/pool.d/www.conf && \
    sed -i "s/listen.owner = .*/listen.owner = ${USER}/" /etc/php/7.4/fpm/pool.d/www.conf && \
    sed -i "s/listen.group = .*/listen.group = ${USER}/" /etc/php/7.4/fpm/pool.d/www.conf && \
    sed -i "s/;catch_workers_output = .*/catch_workers_output = yes/" /etc/php/7.4/fpm/pool.d/www.conf && \
    sed -i "s/^user.*/user ${USER};/" /etc/nginx/nginx.conf && \
    mkdir -p $APPDIR && \
    chown -R $USER:$USER $APPDIR && \
    find $APPDIR -type d -exec chmod 775 {} + && \
    find $APPDIR -type f -exec chmod 664 {} + && \
    chmod +x /usr/local/bin/docker-entrypoint && \
    chmod +x /usr/local/bin/start

EXPOSE 80

ENTRYPOINT ["docker-entrypoint"]

CMD ["start"]
