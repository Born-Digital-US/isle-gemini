FROM php:7.4.3-apache
# Apache https://github.com/docker-library/php/blob/04c0ee7a0277e0ebc3fcdc46620cf6c1f6273100/7.4/buster/apache/Dockerfile

## General Dependencies
RUN GEN_DEP_PACKS="software-properties-common \
    gnupg \
    zip \
    unzip \
    git \
    gettext-base" && \
    echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections && \
    apt-get update && \
    apt-get install --no-install-recommends -y $GEN_DEP_PACKS && \
    ## Cleanup phase.
    apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

COPY rootfs /

# Composer & Gemini
# @see: Composer https://github.com/composer/getcomposer.org/commits/master (replace hash below with most recent hash)
# @see: Gemini https://github.com/Islandora/Crayfish

ARG GEMINI_JWT_ADMIN_TOKEN
ARG GEMINI_LOG_LEVEL

ENV PATH=$PATH:$HOME/.composer/vendor/bin \
    COMPOSER_ALLOW_SUPERUSER=1 \
    COMPOSER_HASH=${COMPOSER_HASH:-b9cc694e39b669376d7a033fb348324b945bce05} \
    GEMINI_BRANCH=dev

RUN curl https://raw.githubusercontent.com/composer/getcomposer.org/$COMPOSER_HASH/web/installer --output composer-setup.php --silent && \
    php composer-setup.php --filename=composer --install-dir=/usr/local/bin && \
    rm composer-setup.php && \
    mkdir -p /opt/crayfish && \
    git clone -b $GEMINI_BRANCH https://github.com/Islandora/Crayfish.git /opt/crayfish && \
    cp /opt/crayfish/Gemini/cfg/config.example.yaml /opt/crayfish/Gemini/cfg/config.yaml && \
    composer install -d /opt/crayfish/Gemini && \
    chown -Rv www-data:www-data /opt/crayfish && \
    mkdir /var/log/islandora && \
    chown www-data:www-data /var/log/islandora && \
    envsubst < /opt/templates/syn-settings.xml.template > /opt/crayfish/Gemini/syn-settings.xml && \
    envsubst < /opt/templates/config.yaml.template > /opt/crayfish/Gemini/cfg/config.yaml && \
    a2dissite 000-default && \
    a2enmod rewrite deflate headers expires proxy proxy_http proxy_html proxy_connect remoteip xml2enc cache_disk

ARG BUILD_DATE
ARG VCS_REF
ARG VERSION
LABEL org.label-schema.build-date=$BUILD_DATE \
      org.label-schema.name="ISLE 8 Gemini Image" \
      org.label-schema.description="ISLE 8 Gemini" \
      org.label-schema.url="https://islandora.ca" \
      org.label-schema.vcs-ref=$VCS_REF \
      org.label-schema.vcs-url="https://github.com/Islandora-Devops/isle-gemini" \
      org.label-schema.vendor="Islandora Devops" \
      org.label-schema.version=$VERSION \
      org.label-schema.schema-version="1.0"

ENTRYPOINT ["docker-php-entrypoint"]

STOPSIGNAL SIGWINCH

WORKDIR /opt/crayfish/Gemini/

EXPOSE 8000
CMD ["apache2-foreground"]