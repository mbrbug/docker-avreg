FROM debian:stretch AS builder

RUN echo "deb http://archive.debian.org/debian stretch main" > /etc/apt/sources.list \
&& echo "deb http://archive.debian.org/debian stretch-backports main" >> /etc/apt/sources.list \
&& echo  "deb http://archive.debian.org/debian-security stretch/updates main" >> /etc/apt/sources.list

# add avreg repository to application sources
#RUN echo "deb http://avreg.net/repos/6.3/debian/ stretch main contrib non-free" >> /etc/apt/sources.list

# remove policy file to allow start services while apt-get install
#RUN rm -rf /usr/sbin/policy-rc.d && mkdir /etc/avreg && mkdir /video
#ADD /conf/avreg-mon.secret /etc/avreg
#ADD /conf/avreg-unlink.secret /etc/avreg
#ADD /conf/avreg.conf /etc/avreg
#ADD /conf/avreg-site.secret /etc/avreg
#ADD /conf/avregd.secret /etc/avreg

# prepare answers to install mysql
#RUN echo "mysql-server mysql-server/root_password password 12345" | debconf-set-selections
#RUN echo "mysql-server mysql-server/root_password_again password 12345" | debconf-set-selections

# install avreg and remove any pid ghosts of it's service by stopping the service
RUN DEBIAN_FRONTEND=noninteractive \
	echo "deb http://avreg.net/repos/6.3-html5/debian/ stretch main contrib non-free" >> /etc/apt/sources.list \
	&& rm -rf /usr/sbin/policy-rc.d && mkdir /etc/avreg && mkdir /video \
	# && echo "mysql-server mysql-server/root_password password 12345" | debconf-set-selections \
	# && echo "mysql-server mysql-server/root_password_again password 12345" | debconf-set-selections \
	&& apt-get update && apt-get install -y rsyslog cron nano postgresql less vim mc \
	&& service postgresql restart \
	&& apt-get install -y --allow-unauthenticated avreg-server-pgsql \
    && service avreg stop

FROM builder
	# && sed -i 's/db-user = '.*'/db-user = '"'avreg-mon'"' /' /etc/avreg/avreg-mon.secret \
RUN	sed -i 's/db-passwd = '.*'/db-passwd = '"'oeWOkHWJku6sx0EIULG42ZCBa4JMGr7_'"' /' /etc/avreg/avreg-mon.secret \
	# && sed -i 's/db-user = '.*'/db-user = '"'avreg-unlink'"' /' /etc/avreg/avreg-unlink.secret \
	&& sed -i 's/db-passwd = '.*'/db-passwd = '"'BdT7dYWKSXcidqVC9NSMcPzoyWKOGr7_'"' /' /etc/avreg/avreg-unlink.secret \
	# && sed -i 's/db-user = '.*'/db-user = '"'avreg-site'"' /' /etc/avreg/avreg-site.secret \
	&& sed -i 's/db-passwd = '.*'/db-passwd = '"'1dsjsp3UeCRY4IsSwfL0rnmaqEVEGr7_'"' /' /etc/avreg/avreg-site.secret \
	# && sed -i 's/db-user = '.*'/db-user = '"'avregd'"' /' /etc/avreg/avregd.secret \
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
	# && echo '\n' >> /etc/cron.d/avreg-unlink \
	# && echo "# or every day, at night at 03:27" >> /etc/cron.d/avreg-unlink \
	# && echo 27 3 \* \* \* root  /usr/sbin/avreg-unlink \"\..\`date -d\'0 day ago\' \'+%F\'\`\" \>\> \/var\/log\/cron.log >> /etc/cron.d/avreg-unlink
#RUN mkfifo --mode 0666 /var/log/cron.log

# Add crontab file in the cron directory
# cron to delete after 10 days
ADD crontab /etc/cron.d/avreg-unlink2

# Give execution rights on the cron job
RUN chmod 0644 /etc/cron.d/avreg-unlink2 \
	&& touch /var/log/cron.log

# Create the log file to be able to run tail
#RUN touch /var/log/cron.log

# entry point will start mysql, apache2, and avreg services and stop them as well on demand
ADD entry_point.sh /
CMD ["/entry_point.sh"]
#CMD ["/bin/bash", "-c", "cron && tail -f /var/log/cron.log"]

#ADD /conf/avreg-mon.secret /etc/avreg
#ADD /conf/avreg-unlink.secret /etc/avreg
#ADD /conf/avreg.conf /etc/avreg
#ADD /conf/avreg-site.secret /etc/avreg
#ADD /conf/avregd.secret /etc/avreg

#ADD /conf/20-avregd.conf /etc/rsyslog.d/

EXPOSE 80
