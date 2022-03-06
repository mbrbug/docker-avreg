#!/bin/bash

_cleanup() { 
	echo "Stopping services..." 

	service avreg stop
	service apache2 stop
	service postgresql stop
	service rsyslog stop
	service cron stop

	kill -s SIGTERM $!

	echo "...container stopped."
                                                 
	exit 0
}

echo "Starting services..." 

# remove any ghost service pids in case if container was incorrectly killed 
service avreg stop
service apache2 stop
# service mysql stop
service rsyslog stop
service cron stop

#service mysql 
service postgresql start
service cron start
service rsyslog start
service apache2 start
service apache-htcacheclean start
# service memcached start
# service php7.4-fpm start
service avreg start


echo "...services started."

trap _cleanup SIGTERM
trap _cleanup SIGINT

while [ 1 ]
do                                                                         
  sleep 60 &                                                             
  wait $!                                                                
done
