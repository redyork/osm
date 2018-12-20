#!/bin/bash

# Usage: osrm_update.sh FIRST_CONTAINER_NAME SECOND_CONTAINER_NAME

WRKDIR=/srv/gis

cd $WRKDIR

if [ -z "$1" ]; then
    echo 'First container name not specified.'
    exit 1
fi

if [ -z "$2" ]; then
    echo 'Second container name not specified.'
    exit 1
fi

# Let`s find out wich one is running
dchck=`docker container exec $1 hostname`
if [ -z "$dchck" ]; then
    dchck=`docker container exec $2 hostname`
    if [ -z "$dchck" ]; then
	echo 'Wrong (old) container name or container not running'
	exit 1
    else
	OLDOSRM=$2
	NEWOSRM=$1
    fi
else
    OLDOSRM=$1
    NEWOSRM=$2
fi

echo $dchck
echo '-------------------'

if [ -z "$dchck" ]; then
    echo 'Wrong (old) container name or container not running'
    exit 1
fi

nchck=`docker-compose config --services |grep "^$NEWOSRM$"`

echo $nchck
echo '-------------------'


if [ -z "$nchck" ]; then
    echo 'Wrong (new) container name.'
    exit 1
fi


docker-compose up -d $NEWOSRM

newdcip=`docker inspect --format='{{range .NetworkSettings.Networks}}{{print .IPAddress}}{{end}}' $NEWOSRM`
olddcip=`docker inspect --format='{{range .NetworkSettings.Networks}}{{print .IPAddress}}{{end}}' $OLDOSRM`


while true; do
    #osrmstatus=`docker-compose logs $NEWOSRM|tail -n 100`
    #osrmready=`echo $osrmstatus|grep 'running and waiting for requests'`
    osrmstatus=`curl -m 1 'http://'$newdcip':5000/route/v1/walking/-75.556521,39.746364;-75.545551,39.747228?overview=false'`
    osrmready=`echo $osrmstatus|grep 'routes'`
    echo -n ".$osrmready"
    if [ ! -z "$osrmready" ]; then
	echo OK
	echo 'Replacing containers'
	docker-compose stop $OLDOSRM
	docker rm -v $OLDOSRM
	iptn=`iptables -L -t nat --line-numbers|grep 'dpt:5000'`
	if [ ! -z "$iptn" ]; then
	    iptables -t nat -D DOCKER $iptn
	fi
	iptables -t nat -I DOCKER -p tcp --dport 5000 -j DNAT --to-destination $newdcip:5000
	exit 0
    fi
    sleep 1
done


