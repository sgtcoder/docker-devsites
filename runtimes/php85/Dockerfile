FROM debian:trixie-slim

# Prebuilt PHP from packages.sury.org, the same php8.5-* packages as PHP_EXTS in sh/install_packages.sh
# (minus dev). Nothing compiles, so the emulated arm64 build only unpacks packages.
# php8.5-common already has calendar, exif, ffi, ftp, gettext, shmop, sockets and sysv*.
ARG PHP=8.5
ENV PHP_MEMORY_LIMIT=256M \
    PHP_UPLOAD_MAX_FILE_SIZE=100M \
    PHP_POST_MAX_SIZE=100M \
    PHP_MAX_EXECUTION_TIME=99 \
    COMPOSER_HOME=/composer
RUN apt-get update && apt-get install -y --no-install-recommends ca-certificates curl git unzip socat \
    && curl -fsSLo /tmp/sury.deb https://packages.sury.org/debsuryorg-archive-keyring.deb \
    && dpkg -i /tmp/sury.deb && rm /tmp/sury.deb \
    && echo "deb [signed-by=/usr/share/keyrings/debsuryorg-archive-keyring.gpg] https://packages.sury.org/php/ trixie main" \
        > /etc/apt/sources.list.d/php.list \
    && apt-get update && apt-get install -y --no-install-recommends \
        php$PHP-bcmath php$PHP-bz2 php$PHP-cli php$PHP-common php$PHP-curl php$PHP-dba php$PHP-fpm \
        php$PHP-gd php$PHP-gearman php$PHP-gmp php$PHP-gnupg php$PHP-igbinary php$PHP-imagick php$PHP-intl \
        php$PHP-maxminddb php$PHP-mbstring php$PHP-mcrypt php$PHP-mysql php$PHP-oauth php$PHP-pgsql php$PHP-raphf \
        php$PHP-readline php$PHP-redis php$PHP-soap php$PHP-sqlite3 php$PHP-ssh2 php$PHP-uuid \
        php$PHP-xdebug php$PHP-xml php$PHP-xmlrpc php$PHP-yaml php$PHP-zip \
    && rm -rf /var/lib/apt/lists/*

# Limits come from the compose file's PHP_* variables, for CLI and FPM alike.
# Xdebug is installed but off; enable per command with XDEBUG_MODE=debug.
# Opcache off so edits show up immediately.
RUN printf '%s\n' \
        '; priority=99' \
        'memory_limit = ${PHP_MEMORY_LIMIT}' \
        'upload_max_filesize = ${PHP_UPLOAD_MAX_FILE_SIZE}' \
        'post_max_size = ${PHP_POST_MAX_SIZE}' \
        'max_execution_time = ${PHP_MAX_EXECUTION_TIME}' \
        'opcache.enable = 0' \
        'xdebug.mode = "off"' \
        > /etc/php/$PHP/mods-available/devsites.ini \
    && phpenmod -v $PHP devsites

# FPM runs as www-data on :9000 for nginx. Web requests run as local, so Laravel loads .env.local
# when a project has one. Not set container-wide: it would override phpunit.xml's APP_ENV=testing.
# Plain http locally: turn off laravel-functions' https redirect and secure cookies.
RUN sed -i -e 's|^error_log = .*|error_log = /proc/self/fd/2|' -e 's|^pid = .*|pid = /run/php/php-fpm.pid|' \
        /etc/php/$PHP/fpm/php-fpm.conf \
    && printf '%s\n' \
        '[www]' \
        'listen = 9000' \
        'pm = dynamic' \
        'pm.max_children = 20' \
        'pm.start_servers = 2' \
        'pm.min_spare_servers = 1' \
        'pm.max_spare_servers = 4' \
        'clear_env = no' \
        'catch_workers_output = yes' \
        'decorate_workers_output = no' \
        'env[APP_ENV] = "local"' \
        'env[DISABLE_SSL] = "true"' \
        'env[SESSION_SECURE_COOKIE] = "false"' \
        > /etc/php/$PHP/fpm/pool.d/www.conf \
    && ln -s /usr/sbin/php-fpm$PHP /usr/local/sbin/php-fpm \
    && mkdir -p /run/php /composer /projects /var/www \
    && chown www-data:www-data /run/php /composer /var/www

COPY --from=composer:2 /usr/bin/composer /usr/local/bin/composer
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
COPY 60-devsites-forward.sh /etc/entrypoint.d/60-devsites-forward.sh

# Node 24 and the latest npm, as on the Mac (update.sh), so npm writes identical lock files in both.
COPY --from=node:24-trixie-slim /usr/local/bin/node /usr/local/bin/node
COPY --from=node:24-trixie-slim /usr/local/lib/node_modules /usr/local/lib/node_modules
RUN ln -s ../lib/node_modules/npm/bin/npm-cli.js /usr/local/bin/npm \
    && ln -s ../lib/node_modules/npm/bin/npx-cli.js /usr/local/bin/npx \
    && npm install --no-audit --no-fund -g npm@latest

# Chrome for Browsershot/Puppeteer, with its apt libraries (--install-deps). Every project's Puppeteer
# uses this one through PUPPETEER_EXECUTABLE_PATH instead of downloading its own.
ENV PUPPETEER_EXECUTABLE_PATH=/usr/local/bin/chrome \
    PUPPETEER_SKIP_DOWNLOAD=true
RUN apt-get update && apt-get install -y --no-install-recommends fonts-liberation \
    && npx -y @puppeteer/browsers install chrome@stable --path /opt/chrome --install-deps \
    && ln -s "$(find /opt/chrome -type f -name chrome -perm -u+x | head -n1)" /usr/local/bin/chrome \
    && chrome --version \
    && rm -rf /var/lib/apt/lists/* /root/.npm

USER www-data
WORKDIR /projects
EXPOSE 9000
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["php-fpm", "-F"]
