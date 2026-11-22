FROM serversideup/php:8.5-fpm

USER root
# Matches the server's PHP_EXTS in sh/install_packages.sh; the base image already has the rest.
# Xdebug is installed but off; enable per command with XDEBUG_MODE=debug.
RUN install-php-extensions intl gd bcmath exif gmp sockets \
        calendar ffi ftp gettext shmop sysvmsg sysvsem sysvshm \
        bz2 dba gearman gnupg igbinary imagick maxminddb mcrypt mysqli oauth raphf \
        soap ssh2 uuid xdebug xmlrpc xsl yaml \
    && printf 'xdebug.mode="off"\n' > /usr/local/etc/php/conf.d/zz-devsites-xdebug.ini \
    && apt-get update && apt-get install -y --no-install-recommends socat \
    && rm -rf /var/lib/apt/lists/*
# Web requests run as local, so Laravel loads .env.local when a project has one.
# Not set container-wide: it would override phpunit.xml's APP_ENV=testing.
# Plain http locally: turn off laravel-functions' https redirect and secure cookies.
RUN printf '[${PHP_FPM_POOL_NAME}]\nenv[APP_ENV] = "local"\nenv[DISABLE_SSL] = "true"\nenv[SESSION_SECURE_COOKIE] = "false"\n' > /usr/local/etc/php-fpm.d/zzzz-devsites.conf
COPY 60-devsites-forward.sh /etc/entrypoint.d/60-devsites-forward.sh
# Node 24 and the latest npm, as on the Mac (update.sh), so npm writes identical lock files in both.
# Also Chrome's system libraries for Browsershot/Puppeteer.
# Chrome itself comes from each project: npx puppeteer browsers install chrome
COPY --from=node:24-trixie-slim /usr/local/bin/node /usr/local/bin/node
COPY --from=node:24-trixie-slim /usr/local/lib/node_modules /usr/local/lib/node_modules
RUN ln -s ../lib/node_modules/npm/bin/npm-cli.js /usr/local/bin/npm \
    && ln -s ../lib/node_modules/npm/bin/npx-cli.js /usr/local/bin/npx \
    && npm install --no-audit --no-fund -g npm@latest \
    && apt-get update && apt-get install -y --no-install-recommends \
        ca-certificates fonts-liberation libasound2t64 libatk-bridge2.0-0t64 libatk1.0-0t64 \
        libatspi2.0-0t64 libcairo2 libcups2t64 libdbus-1-3 libdrm2 libgbm1 libglib2.0-0t64 \
        libnspr4 libnss3 libpango-1.0-0 libx11-6 libxcb1 libxcomposite1 libxdamage1 \
        libxext6 libxfixes3 libxkbcommon0 libxrandr2 \
    && rm -rf /var/lib/apt/lists/*
USER www-data
