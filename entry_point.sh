#!/bin/bash

_cleanup() { 
	echo "Stopping services..." 

	service avreg stop
	service apache2 stop
	service mysql stop

	kill -s SIGTERM $!

	echo "...container stopped."
                                                 
	exit 0
}

echo "Starting services..." 

# remove any ghost service pids in case if container was incorrectly killed 
service avreg stop
service apache2 stop
service mysql stop

if [ ! -f /avreg6_db/initialized ]; then
	mkdir /avreg6_db
	mv /var/lib/mysql/avreg6_db/* /avreg6_db
	touch /avreg6_db/initialized	
fi
rm -rf /var/lib/mysql/avreg6_db
ln -s /avreg6_db /var/lib/mysql/avreg6_db
chown mysql:mysql /var/lib/mysql/avreg6_db

service mysql start
service apache2 start
service avreg start

echo "...services started."

trap _cleanup SIGTERM
trap _cleanup SIGINT

while [ 1 ]
do                                                                         
  sleep 60 &                                                             
  wait $!                                                                
done
