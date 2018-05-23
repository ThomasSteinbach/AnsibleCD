FROM ubuntu:16.04
# with info from https://docs.diladele.com/administrator_guide_4_0/system_configuration/https_filtering/recompile_squid.html

RUN sed -i 's%# deb-src%deb-src%g' /etc/apt/sources.list
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
      devscripts \
      build-essential \
      fakeroot \
      libssl-dev \
      openssl

RUN apt-get source squid3
RUN apt-get build-dep -y squid3

COPY rules.patch rules.patch
RUN patch squid3*/debian/rules < rules.patch

RUN cd squid3* && \
    dpkg-buildpackage -rfakeroot -b

RUN tar czf squid.debs.tar.gz squid*.deb

FROM ubuntu:16.04

COPY --from=0 /squid.debs.tar.gz /tmp/squid.debs.tar.gz

RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
      libgssapi-krb5-2 \
      libltdl7 \
      libecap3 \
      libnetfilter-conntrack3 \
      squid-langpack \
      ssl-cert \
      ca-certificates \
      logrotate \
      libexpat1 \
      libldap-2.4-2 \
      libxml2 \
      netbase && \
    apt-get clean

RUN tar xzf /tmp/squid.debs.tar.gz && \
    dpkg --install squid-common_3*_all.deb && \
    dpkg --install squid_3*_amd64.deb && \
    dpkg --install squidclient_3.*_amd64.deb && \
    rm /squid*.deb

# configure ssl_crtd
RUN /usr/lib/squid3/ssl_crtd -c -s /var/lib/ssl_db; \
    chown -R proxy:proxy /var/lib/ssl_db

RUN cd /etc/squid; \
    mkdir ssl_cert; \
    chown proxy:proxy ssl_cert; \
    cd ssl_cert; \
    openssl req -new -newkey rsa:2048 -sha256 -days 3650 -nodes -x509 -keyout myCA.pem -subj "/C=DE/ST=AnsibleCI/L=AnsibleCI/O=AnsibleCI/CN=www.xarif.de" -out myCA.pem; \
    openssl x509 -in myCA.pem -outform DER -out myCA.der

COPY squid.conf /etc/squid/squid.conf
COPY start.sh /start.sh
RUN chmod +x /start.sh

EXPOSE 8000

VOLUME /var/cache/squid3

ENTRYPOINT ["/start.sh"]
