FROM haproxy:alpine
#FROM haproxy:1.7-alpine
LABEL Jon Proton <jon@opscode.space>

ENTRYPOINT ["/prepare-entrypoint"]
CMD haproxy -p /var/run/haproxy.pid -- /etc/haproxy/*.cfg
EXPOSE 80 443

ENV \
    MODE=NORMAL \
    # Odoo mode special variables
    ODOO_LONGPOLLING_PORT=8072 \
    # Use `FORCE` or `REMOVE`
    WWW_PREFIX=REMOVE \
    # Use `false` to ask for real certs
    STAGING=true \
    # Use `true` to continue on cert fetch failure
    CONTINUE_ON_CERTONLY_FAILURE=false \
    # Fill your data here
    EMAIL=example@example.com \
    DOMAINS=example.com,example.org \
    RSA_KEY_SIZE=4096 \
    # Command to fetch certs at container boot.  We use port 80 here because haproxy isn't running yet.
    # for renew, we use port 90 for certbot, because haproxy is bound to port 80, and redirects to port 90
    CERTONLY="certbot certonly --debug --http-01-port 80 --post-hook /usr/local/bin/update-crt-list" \
    # Command to monthly renew certs
    RENEW="certbot certonly --debug  --http-01-port 90 --post-hook /usr/local/bin/update-crt-list"

# Certbot (officially supported Let's Encrypt client)
# SEE https://github.com/certbot/certbot/pull/4032
COPY cli.ini /usr/src/

USER root

# RUN apk update \
#     && apk add --no-cache --virtual .certbot-deps \
#         py3-pip \
#         #py-pip \
#         #&& pip install --upgrade pip \
#         #&& pip3 install --upgrade pip \
#         && which pip3 \
#         && if [ ! -e /usr/bin/pip ]; then ln -s /usr/bin/pip3 /usr/bin/pip ; fi \
#         && if [[ ! -e /usr/bin/python ]]; then ln -sf /usr/bin/python3 /usr/bin/python; fi 
#         ##&& pip install --no-cache-dir setuptools_rust

# debug:
#  docker run -it --entrypoint /bin/sh --user root haproxy:alpine

# to update deps, see cerbot Dockerfile
# https://github.com/certbot-docker/certbot-docker/blob/master/core/Dockerfile
RUN apk update \
    && apk add --no-cache \
        dialog \
        augeas-libs \
        libffi \
        libssl1.1 \
        openssl \
        wget \
        ca-certificates \
        binutils \
        python3 \
        py3-pip \
    && ln -s /usr/bin/pip3 /usr/bin/pip 2>/dev/null \
    && pip install --upgrade pip
        
# RUN apk add --no-cache \
#         #python-dev \
#         python3 \
#         #python3-dev \
#         #py-pip \
#         py3-pip \
#         && pip install --upgrade pip

# if I don't have CRYPTOGRAPHY_DONT_BUILD_RUST=1, certbot installation will fail
# because pip doesn't have rust. It might be okay to take this out later
RUN export CRYPTOGRAPHY_DONT_BUILD_RUST=1 \
    && apk update \
    && apk add --no-cache --virtual .build-deps \
        python3-dev \
        gcc \
        linux-headers \
        openssl-dev \
        musl-dev \
        libffi-dev \
    && apk del certbot \
    && pip install certbot \
    && apk del .build-deps

# Cron
RUN apk add --no-cache dcron
RUN ln -s /usr/local/bin/renew /etc/periodic/daily/renew

# Utils
RUN apk add --no-cache gettext socat
RUN mkdir -p /var/lib/haproxy && touch /var/lib/haproxy/server-state
COPY conf/* /etc/haproxy/
COPY prepare-entrypoint /
COPY bin/* /usr/local/bin/
RUN chmod +x /usr/local/bin/* && chmod +x /prepare-entrypoint

VOLUME /var/spool/cron/cronstamps /etc/letsencrypt

# Metadata
ARG VCS_REF
ARG BUILD_DATE
# LABEL org.label-schema.schema-version="1.0" \
#       org.label-schema.vendor=Tecnativa \
#       org.label-schema.build-date="$BUILD_DATE" \
#       org.label-schema.vcs-ref="$VCS_REF" \
#       org.label-schema.vcs-url="https://github.com/Tecnativa/docker-haproxy-letsencrypt"
