FROM debian

MAINTAINER @palle version: 1

RUN apt-get update

RUN apt-get -y install \
    apt-utils \
    apache2 \
    php5 \
    php5-gd \
    php5-mysql \
    perl \
    libxml-simple-perl \
    libdbi-perl \
    libapache-dbi-perl \
    libdbd-mysql-perl \
    libio-compress-perl \
    libxml-simple-perl \
    libsoap-lite-perl \
    libarchive-zip-perl \
    libnet-ip-perl \
    libphp-pclzip \
    libsoap-lite-perl \
    libarchive-zip-perl \
    htop \
    git \
    wget \
    tar \
    unzip \
    nano \
    make

RUN cpan -i XML::Entities

#Set time zone Europe/Paris
RUN cp /usr/share/zoneinfo/Europe/Paris /etc/localtime

#Set permission and run cron
ENV APACHE_RUN_USER www-data
ENV APACHE_RUN_GROUP www-data
ENV APACHE_LOG_DIR /var/log/apache2
ENV POOLING enable


RUN /usr/sbin/a2dissite 000-default
RUN /usr/sbin/a2enmod rewrite
RUN /usr/sbin/a2ensite default-ssl
RUN /usr/sbin/a2enmod ssl

RUN git clone https://github.com/OCSInventory-NG/OCSInventory-Server.git /tmp/ocs
RUN git clone https://github.com/OCSInventory-NG/OCSInventory-ocsreports.git /tmp/ocs/ocsreports

WORKDIR /tmp/ocs/Apache
# A revoir
cp -R /usr/lib/Apache
cp -R /tmp/ocs/etc/logrotate.d/ocsinventory-server /etc/logrotate.d/ \
mkdir -p /etc/ocsinventory-server/{plugins,perl} \
mkdir -p /usr/share/ocsinventory-reports


WORKDIR /tmp/ocs
RUN cp -R ocsreports /usr/share/ocsinventory-reports \
    chown -R www-data: /usr/share/ocsinventory-reports \
    mkdir -p /var/lib/ocsinventory-reports/{download,ipd,logs,scripts,snmp} \
    chown root:apache -R /var/lib/ocsinventory-reports/{download,ipd,logs,scripts,snmp} \
    cp binutils/ipdiscover-util.pl /usr/share/ocsinventory-reports/ocsreports/ipdiscover-util.pl \
    chown www-data: /usr/share/ocsinventory-reports/ocsreports/ipdiscover-util.pl \
    chmod 755 /usr/share/ocsinventory-reports/ocsreports/ipdiscover-util.pl

COPY DB/dbconfig.inc.php /usr/share/ocsinventory-reports/ocsreports/
COPY DB/init_db.sh sql/ocsweb.sql /tmp/
RUN chmod +w /usr/share/ocsinventory-reports/ocsreports/dbconfig.inc.php \
    chmod +x /tmp/init_db.sh \
    /tmp/init_db.sh \
    rm -fR /tmp/ocs                    

EXPOSE 443
EXPOSE 80

RUN echo "/usr/sbin/apache2ctl -D FOREGROUND" >> /root/run.sh && \
    chmod +x /root/run.sh

CMD ["/bin/bash", "/root/run.sh"]
