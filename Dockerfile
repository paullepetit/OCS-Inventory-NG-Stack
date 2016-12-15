FROM debian:latest

MAINTAINER @palle version:1

RUN apt-get update

# Installation des paquet perl depuis le dépot DEBIAN, et quelques utilitaires
RUN apt-get -y install \
    apache2 \
    apache2-doc \
    apt-utils \
    php5 \
    php5-gd \
    php5-mysql \
    php5-cgi \
    perl \
    build-essential \
    libapache2-mod-php5 \
    libxml2 \
    libxml-simple-perl \
    libc6-dev \
    libnet-ip-perl \
    libxml-libxml-perl \
    libapache2-mod-perl2 \
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

# Activation des modules
RUN /usr/sbin/a2dissite 000-default
#RUN /usr/sbin/a2ensite default-ssl
RUN /usr/sbin/a2enmod rewrite
RUN /usr/sbin/a2enmod ssl
RUN /usr/sbin/a2enmod authz_user

# DL OCSserver & Ocsreports
RUN wget https://raw.githubusercontent.com/OCSInventory-NG/OCSInventory-Server/master/binutils/docker-download.sh 
RUN sh docker-download.sh

# Copie et création des répertoires principaux
WORKDIR /tmp/ocs/Apache
RUN perl Makefile.PL
RUN make
RUN make install
RUN cp -R blib/lib/Apache /usr/local/share/perl/5.20.2/
RUN cp -R Ocsinventory /usr/local/share/perl/5.20.2/
RUN cp /tmp/ocs/etc/logrotate.d/ocsinventory-server /etc/logrotate.d/
RUN mkdir -p /etc/ocsinventory-server/plugins
RUN mkdir -p /etc/ocsinventory-server/perl
RUN mkdir -p /usr/share/ocsinventory-reports/ocsreports

# Configure les variable d'environement
ENV APACHE_RUN_USER     www-data
ENV APACHE_RUN_GROUP    www-data
ENV APACHE_LOG_DIR      /var/log/apache2
ENV APACHE_PID_FILE     /var/run/apache2.pid
ENV APACHE_RUN_DIR      /var/run/apache2f
ENV APACHE_LOCK_DIR     /var/lock/apache2
ENV APACHE_LOG_DIR      /var/log/apache2

# Copie et création des répertoires principaux
WORKDIR /tmp/ocs
RUN cp -R ocsreports/* /usr/share/ocsinventory-reports/ocsreports
RUN rm -rf /usr/share/ocsinventory-reports/ocsreports/dbconfig.inc.php
ADD dbconfig.inc.php /usr/share/ocsinventory-reports/ocsreports/
RUN chown -R www-data: /usr/share/ocsinventory-reports/
RUN mkdir -p /var/lib/ocsinventory-reports/download
RUN mkdir -p /var/lib/ocsinventory-reports/ipd
RUN mkdir -p /var/lib/ocsinventory-reports/logs
RUN mkdir -p /var/lib/ocsinventory-reports/scripts
RUN mkdir -p /var/lib/ocsinventory-reports/snmp

# Création des droits
RUN chmod -R +w /var/lib/ocsinventory-reports
RUN chown www-data: -R /var/lib/ocsinventory-reports/
RUN cp binutils/ipdiscover-util.pl /usr/share/ocsinventory-reports/ocsreports/ipdiscover-util.pl
RUN chown www-data: /usr/share/ocsinventory-reports/ocsreports/ipdiscover-util.pl
RUN chmod 755 /usr/share/ocsinventory-reports/ocsreports/ipdiscover-util.pl
RUN chmod +w /usr/share/ocsinventory-reports/ocsreports/dbconfig.inc.php
RUN mkdir -p /var/log/ocsinventory-server/
RUN chmod +w /var/log/ocsinventory-server/

# Ajout des conf ocs
ADD /conf/ocsinventory-reports.conf /etc/apache2/conf-available/
ADD /conf/z-ocsinventory-server.conf /etc/apache2/conf-available/

# Activation des conf OCS
RUN ln -s /etc/apache2/conf-available/ocsinventory-reports.conf /etc/apache2/conf-enabled/ocsinventory-reports.conf
RUN ln -s /etc/apache2/conf-available/z-ocsinventory-server.conf /etc/apache2/conf-enabled/z-ocsinventory-server.conf

# Suppression de install.php
RUN rm /usr/share/ocsinventory-reports/ocsreports/install.php

# Exposition des ports
EXPOSE 80
EXPOSE 443
EXPOSE 3306

# Démare Apache2 au lancement du container
ENTRYPOINT [ "/usr/sbin/apache2", "-D", "FOREGROUND" ]
