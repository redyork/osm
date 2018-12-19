#!/bin/bash

if [ "$#" -ne 1 ]; then
    echo "usage: <import|run>"
    echo "commands:"
    echo "    import: Set up the database and import /data.osm.pbf"
    echo "    run: Runs Apache and renderd to serve tiles at /tile/{z}/{x}/{y}.png"
    echo "environment variables:"
    echo "    THREADS: defines number of threads used for importing / tile rendering"
    exit 1
fi

echo '===================================================================='
whoami
echo '===================================================================='
# Setting rights
chown -R renderer /var/lib/mod_tile
#chown renderer /var/lib/mod_tile

#if [ ! -f "/var/lib/mod_tile/render_list_geo.pl"]; then
#fi

cp /render_list_geo.pl /var/lib/mod_tile/render_list_geo.pl &2>1

if [ "$1" = "import" ]; then
    # Initialize PostgreSQL
    # ${POSTGRES_USER}:${POSTGRES_PASSWORD}@${POSTGRES_HOST}:${POSTGRES_PORT}/${POSTGRES_DB}"
    #service postgresql start
    export PGPASSWORD=$POSTGRES_PASSWORD
    export PGHOST=$POSTGRES_HOST
    export PGPORT=$POSTGRES_PORT
    export PGUSER=$POSTGRES_USER
env
echo '===================================================================='
sleep 3

    createuser -h $POSTGRES_HOST -U postgres renderer
    createdb -h $POSTGRES_HOST -U postgres -E UTF8 -O renderer gis
    psql -h $POSTGRES_HOST -U $POSTGRES_USER -d $POSTGRES_DB -c "CREATE EXTENSION postgis;"
    psql -h $POSTGRES_HOST -U $POSTGRES_USER -d $POSTGRES_DB -c "CREATE EXTENSION hstore;"
    psql -h $POSTGRES_HOST -U $POSTGRES_USER -d $POSTGRES_DB -c "ALTER TABLE geometry_columns OWNER TO renderer;"
    psql -h $POSTGRES_HOST -U $POSTGRES_USER -d $POSTGRES_DB -c "ALTER TABLE spatial_ref_sys OWNER TO renderer;"

    psql -h $POSTGRES_HOST -U $POSTGRES_USER -d $POSTGRES_DB -c "alter user renderer with encrypted password 'renderer';"

    # Download Luxembourg as sample if no data is provided
    if [ ! -f /import/data.osm.pbf ]; then
        echo "WARNING: No import file at /data.osm.pbf, so importing Luxembourg as example..."
        wget -nv http://download.geofabrik.de/europe/luxembourg-latest.osm.pbf -O /import/data.osm.pbf
    fi

    # Import data
    #chown renderer:renderer /home/renderer/src/openstreetmap-carto/project.mml.template
    #cp /home/renderer/src/openstreetmap-carto/project.mml.template /home/renderer/src/openstreetmap-carto/project.mml

    # Inserting PSQL credentials in project.mml conf
    chckconf=`cat /home/renderer/src/openstreetmap-carto/project.mml|grep 'host:'`
    if [ -z "$chckconf" ]; then
        sed -i '/dbname:/a \    user: "renderer"\n    password: "renderer"\n    host: "'$PGHOST'"' /home/renderer/src/openstreetmap-carto/project.mml
	sed '1p;60q' /home/renderer/src/openstreetmap-carto/project.mml
        #sed -i '/dbname:/a \    user: "'$PGUSER'"\n    password: "'$PGPASSWORD'"\n    host: "'$PGHOST'"/' /home/renderer/src/openstreetmap-carto/project.mml
        sed -i 's/dbname:.*/dbname: "'$POSTGRES_DB'"/' /home/renderer/src/openstreetmap-carto/project.mml
    else
        sed -i 's/dbname:.*/dbname: "'$POSTGRES_DB'"/' /home/renderer/src/openstreetmap-carto/project.mml
        sed -i 's/user:.*/user: "renderer"/' /home/renderer/src/openstreetmap-carto/project.mml
        sed -i 's/password:.*/password: "renderer"/' /home/renderer/src/openstreetmap-carto/project.mml
        sed -i 's/host:.*/host: "'$PGHOST'"/' /home/renderer/src/openstreetmap-carto/project.mml
	sed '1p;60q' /home/renderer/src/openstreetmap-carto/project.mml
    fi

    #sudo -E -u renderer cd /home/renderer/src/openstreetmap-carto && carto project.mml > mapnik.xml
    sudo -E -u renderer carto /home/renderer/src/openstreetmap-carto/project.mml > /home/renderer/src/openstreetmap-carto/mapnik.xml
    #export PGPASSWORD=$POSTGRES_PASSWORD
    export PGPASSWORD=renderer
    export PGUSER=renderer
    sudo -E -u renderer osm2pgsql -U renderer -d $POSTGRES_DB -H $POSTGRES_HOST --create --slim -G --hstore --tag-transform-script /home/renderer/src/openstreetmap-carto/openstreetmap-carto.lua -C 8192 --number-processes ${THREADS:-4} -S /home/renderer/src/openstreetmap-carto/openstreetmap-carto.style /import/data.osm.pbf
    #osm2pgsql -U renderer -d $POSTGRES_DB -H $POSTGRES_HOST --create --slim -G --hstore --tag-transform-script /home/renderer/src/openstreetmap-carto/openstreetmap-carto.lua -C 8192 --number-processes ${THREADS:-4} -S /home/renderer/src/openstreetmap-carto/openstreetmap-carto.style /data.osm.pbf

    exit 0
fi

mkdir -p /import/osmosis/tmp &2>1
chown -R renderer:renderer /import
chown -R renderer:renderer /map-update.sh

if [ ! -f "/import/state.txt" ]; then
 echo "ERROR: no state.txt file"
else
 if [ ! -f "/import/osmosis/state.txt" ]; then
  cp /import/state.txt /import/osmosis/state.txt
 fi
fi

if [ ! -f "/import/configuration.txt" ]; then
 echo "ERROR: no configuration.txt file"
else
 if [ ! -f "/import/osmosis/configuration.txt" ]; then
  cp /import/configuration.txt /import/osmosis/configuration.txt
 fi
fi



if [ "$1" = "run" ]; then
    # Initialize PostgreSQL and Apache
    #service postgresql start

    chown renderer:renderer /home/renderer/src/openstreetmap-carto/project.mml.template
    #cp /home/renderer/src/openstreetmap-carto/project.mml.template /home/renderer/src/openstreetmap-carto/project.mml

    # Inserting PSQL credentials in project.mml conf
    #sed -i '/dbname:/a \    user: "'$PGUSER'"\n    password: "'$PGPASSWORD'"\n    host: "'$PGHOST'"/' /home/renderer/src/openstreetmap-carto/project.mml
    #sed -i 's/dbname:.*/dbname: "'$POSTGRES_DB'"/' /home/renderer/src/openstreetmap-carto/project.mml

    sudo -E -u renderer carto /home/renderer/src/openstreetmap-carto/project.mml > /home/renderer/src/openstreetmap-carto/mapnik.xml

    service apache2 restart

    # Configure renderd threads
    sed -i -E "s/num_threads=[0-9]+/num_threads=${THREADS:-4}/g" /usr/local/etc/renderd.conf
    sed -i -e "s/localhost/$POSTGRES_HOST/" /usr/local/etc/renderd.conf

    # Run
    sudo -u renderer renderd -f -c /usr/local/etc/renderd.conf

    exit 0
fi

echo "invalid command"
exit 1