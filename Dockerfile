FROM debian:stretch AS builder

RUN echo "deb http://archive.debian.org/debian stretch main" > /etc/apt/sources.list \
&& echo "deb http://archive.debian.org/debian stretch-backports main" >> /etc/apt/sources.list \
&& echo  "deb http://archive.debian.org/debian-security stretch/updates main" >> /etc/apt/sources.list

RUN DEBIAN_FRONTEND=noninteractive \
	echo "deb http://avreg.net/repos/6.3-html5/debian/ stretch main contrib non-free" >> /etc/apt/sources.list \
	&& rm -rf /usr/sbin/policy-rc.d && mkdir /etc/avreg && mkdir /video \
	&& apt-get update && apt-get install -y rsyslog cron nano postgresql less vim mc \
	&& service postgresql restart \
	&& apt-get install -y --allow-unauthenticated avreg-server-pgsql \
    && service avreg stop

FROM builder

RUN	sed -i 's/db-passwd = '.*'/db-passwd = '"'oeWOkHWJku6sx0EIULG42ZCBa4JMGr7_'"' /' /etc/avreg/avreg-mon.secret \
	&& sed -i 's/db-passwd = '.*'/db-passwd = '"'BdT7dYWKSXcidqVC9NSMcPzoyWKOGr7_'"' /' /etc/avreg/avreg-unlink.secret \
	&& sed -i 's/db-passwd = '.*'/db-passwd = '"'1dsjsp3UeCRY4IsSwfL0rnmaqEVEGr7_'"' /' /etc/avreg/avreg-site.secret \
	&& sed -i 's/db-passwd = '.*'/db-passwd = '"'0m8w0U9OtRMoa9YP8a3U7k2MD7McGr7_'"' /' /etc/avreg/avregd.secret \
	&& sed -i "s/127.0.0.1/192.168.111.2/" /etc/avreg/avreg.conf \
	&& sed -i 's/DocumentRoot \/var\/www\/html/DocumentRoot \/usr\/share\/avreg-site/' /etc/apache2/sites-available/000-default.conf \
	&& sed -i 's/\/avreg\/media/\/media/' /etc/avreg/site-apache2-user.conf \
	&& sed -i 's/\/var\/spool\/avreg/\/video/' /etc/avreg/site-apache2-user.conf \
	&& sed -i "s/Alias '\/avreg'/#Alias '\/avreg'/" /etc/avreg/site-apache2-user.conf \
	&& sed -i "s/avreg-site {/avreg-site {\nprefix = ''/" /etc/avreg/avreg.conf \
	&& sed -i "s/; storage-dir = '\/home\/avreg'/storage-dir = '\/video'/" /etc/avreg/avreg.conf \
	&& sed -i 's/server-name = ".*"/server-name = "homembr videoserver"/' /etc/avreg/avreg.conf \
	&& sed -i 's/Etc\/UTC/Europe\/Moscow/' /etc/timezone \
	&& sed -i 's/;date.timezone =/date.timezone = Europe\/Moscow/' /etc/php/7.0/apache2/php.ini \
	&& usermod -u 1000 avreg && groupmod -g 1000 avreg \
    && rmdir --ignore-fail-on-non-empty /var/lock/avreg \
    && rmdir --ignore-fail-on-non-empty /var/run/avreg

ADD crontab /etc/cron.d/avreg-unlink2

RUN chmod 0644 /etc/cron.d/avreg-unlink2 \
	&& touch /var/log/cron.log

ADD entry_point.sh /
CMD ["/entry_point.sh"]

EXPOSE 80
