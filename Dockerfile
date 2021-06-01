FROM haproxy:alpine
#FROM haproxy:1.7-alpine
LABEL Jon Proton <jon@opscode.space>

ENTRYPOINT ["/prepare-entrypoint.sh"]
CMD haproxy -- /etc/haproxy/*.cfg -p /var/run/haproxy.pid
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
    CERTONLY="certbot certonly --debug --http-01-port 80 --post-hook /usr/local/bin/update-crt-list.sh" \
    # Command to monthly renew certs
    RENEW="certbot certonly --debug  --http-01-port 90 --post-hook /usr/local/bin/update-crt-list.sh"

# Certbot (officially supported Let's Encrypt client)
# SEE https://github.com/certbot/certbot/pull/4032
COPY cli.ini /usr/src/

# to update deps, see cerbot Dockerfile
# https://github.com/certbot-docker/certbot-docker/blob/master/core/Dockerfile
RUN apk add --no-cache --virtual .certbot-deps \
        py3-pip \
        py-pip \
        dialog \
        augeas-libs \
        libffi \
        libssl1.1 \
        openssl \
        wget \
        ca-certificates \
        binutils \
        && pip install --upgrade pip \
        && pip3 install --upgrade pip
# RUN apk add --no-cache --virtual \
#         python-dev \
#         python3-dev \
#         py-pip \
#         py3-pip \
#         && pip install --upgrade pip
RUN apk add --no-cache --virtual .build-deps \
        python-dev \
        python3-dev \
        gcc \
        linux-headers \
        openssl-dev \
        musl-dev \
        libffi-dev \
#    && pip install --no-cache-dir --require-hashes -r /usr/src/certbot.txt \
    && /usr/bin/pip3 install --no-cache-dir certbot \
    && apk del .build-deps

# Cron
RUN apk add --no-cache dcron
RUN ln -s /usr/local/bin/renew.sh /etc/periodic/monthly/renew

# Utils
RUN apk add --no-cache gettext socat
RUN mkdir -p /var/lib/haproxy && touch /var/lib/haproxy/server-state
COPY conf/* /etc/haproxy/
COPY prepare-entrypoint.sh /
COPY bin/* /usr/local/bin/
RUN chmod +x /usr/local/bin/*sh && chmod +x /prepare-entrypoint.sh

VOLUME /var/spool/cron/cronstamps /etc/letsencrypt

# Metadata
ARG VCS_REF
ARG BUILD_DATE
# LABEL org.label-schema.schema-version="1.0" \
#       org.label-schema.vendor=Tecnativa \
#       org.label-schema.build-date="$BUILD_DATE" \
#       org.label-schema.vcs-ref="$VCS_REF" \
#       org.label-schema.vcs-url="https://github.com/Tecnativa/docker-haproxy-letsencrypt"
