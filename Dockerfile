FROM debian:latest

MAINTAINER @palle version:2

RUN apt-get update

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

RUN cp /usr/share/zoneinfo/Europe/Paris /etc/localtime

RUN /usr/sbin/a2dissite 000-default ;\
    /usr/sbin/a2enmod rewrite ;\
    /usr/sbin/a2enmod ssl ;\
    /usr/sbin/a2enmod authz_user

RUN wget https://raw.githubusercontent.com/OCSInventory-NG/OCSInventory-Server/master/binutils/docker-download.sh
RUN sh docker-download.sh

WORKDIR /tmp/ocs/Apache

RUN perl Makefile.PL ;\
    make ;\
    make install

RUN cp -R blib/lib/Apache /usr/local/share/perl/5.20.2/ ;\
    cp -R Ocsinventory /usr/local/share/perl/5.20.2/ ;\
    cp /tmp/ocs/etc/logrotate.d/ocsinventory-server /etc/logrotate.d/

RUN mkdir -p /etc/ocsinventory-server/plugins ;\
    mkdir -p /etc/ocsinventory-server/perl ;\
    mkdir -p /usr/share/ocsinventory-reports/ocsreports

ENV APACHE_RUN_USER     www-data
ENV APACHE_RUN_GROUP    www-data
ENV APACHE_LOG_DIR      /var/log/apache2
ENV APACHE_PID_FILE     /var/run/apache2.pid
ENV APACHE_RUN_DIR      /var/run/apache2f
ENV APACHE_LOCK_DIR     /var/lock/apache2
ENV APACHE_LOG_DIR      /var/log/apache2

WORKDIR /tmp/ocs

RUN cp -R ocsreports/* /usr/share/ocsinventory-reports/ocsreports ;\
    rm -rf /usr/share/ocsinventory-reports/ocsreports/dbconfig.inc.ph

ADD dbconfig.inc.php /usr/share/ocsinventory-reports/ocsreports/

RUN chown -R www-data: /usr/share/ocsinventory-reports/ ;\
    mkdir -p /var/lib/ocsinventory-reports/{download,ipd,logs,scripts,snmp} ;\
    chmod -R +w /var/lib/ocsinventory-reports ;\
    chown www-data: -R /var/lib/ocsinventory-reports

RUN cp binutils/ipdiscover-util.pl /usr/share/ocsinventory-reports/ocsreports/ipdiscover-util.pl

RUN chown www-data: /usr/share/ocsinventory-reports/ocsreports/ipdiscover-util.pl ;\
    chmod 755 /usr/share/ocsinventory-reports/ocsreports/ipdiscover-util.pl ;\
    chmod +w /usr/share/ocsinventory-reports/ocsreports/dbconfig.inc.php ;\
    mkdir -p /var/log/ocsinventory-server/ ;\
    chmod +w /var/log/ocsinventory-server/

ADD /conf/ocsinventory-reports.conf /etc/apache2/conf-available/
ADD /conf/z-ocsinventory-server.conf /etc/apache2/conf-available/

RUN ln -s /etc/apache2/conf-available/ocsinventory-reports.conf /etc/apache2/conf-enabled/ocsinventory-reports.conf
RUN ln -s /etc/apache2/conf-available/z-ocsinventory-server.conf /etc/apache2/conf-enabled/z-ocsinventory-server.conf

RUN rm /usr/share/ocsinventory-reports/ocsreports/install.php ;\
    rm -rf /tmp/ocs

EXPOSE 80
EXPOSE 443
EXPOSE 3306

ENTRYPOINT [ "/usr/sbin/apache2", "-D", "FOREGROUND" ]
