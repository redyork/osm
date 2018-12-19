#!/usr/bin/env bash

set -e

export JAVACMD_OPTIONS="-Xmx2G -Djava.io.tmpdir=/tmp/"

WORKOSM_DIR=/import/osmosis

export PGPASSWORD=$POSTGRES_PASSWORD
export PGHOST=$POSTGRES_HOST
export PGPORT=$POSTGRES_PORT
export PGUSER=$POSTGRES_USER


if [ ! -f "/import/osmosis/state.txt" ]; then
 echo "ERROR: no state.txt file"
 exit 1
fi

if [ ! -f "/import/osmosis/configuration.txt" ]; then
 echo "ERROR: no configuration.txt file"
 exit 1
fi


EXPIRY_MINZOOM=10
EXPIRY_MAXZOOM=20
EXPIRY_METAZOOM=15
EXPIRY_FILE=dirty_tiles


OSMOSIS_WD=/import/osmosis
STATE=/import/state.txt
TMP_OSC=/import/osmosis/tmp/osm-update.osc

# ------ CHECK-PATH ------
EXPIRE_TILES_PATH="/home/renderer/src/mod_tile/render_expired"
OSMOSIS_PATH=`which osmosis`
OSM2PGSQL_PATH=`which osm2pgsql`
DIRTY_TILES_FILENAME="/import/osmosis/tmp/dirty-tiles"
OSM2PGSQL_ARGS="--number-processes 8 -j -a -m -v -d gis -s -C 2000 -S /home/renderer/src/openstreetmap-carto/openstreetmap-carto.style --tag-transform-script /home/renderer/src/openstreetmap-carto/openstreetmap-carto.lua -e 1-14 -o $DIRTY_TILES_FILENAME"

while true; do
    echo "Running Osmosis: `date`"
    cp -f "$STATE" "$OSMOSIS_WD/state.txt"
    if [ -f "$TMP_OSC" ]; then
     rm -f "$TMP_OSC"
    fi
    "$OSMOSIS_PATH" --rri workingDirectory="$OSMOSIS_WD" --wxc "$TMP_OSC" || true
    if diff -q -I '^#' "$STATE" "$OSMOSIS_WD/state.txt" >/dev/null; then
	echo "Sleeping"
	sleep 30
    else
	echo "Suspending render server"
	#sudo /usr/sbin/service renderd stop
	echo "Running osm2pgsql: `date`"
	"$OSM2PGSQL_PATH" $OSM2PGSQL_ARGS "$TMP_OSC"
	cp -f "$OSMOSIS_WD/state.txt" "$STATE"
	echo "Resuming render server"
	#sudo /usr/sbin/service renderd start
	echo "Running expire tiles: `date`"
	"$EXPIRE_TILES_PATH" --min-zoom=$EXPIRY_MINZOOM --max-zoom=$EXPIRY_MAXZOOM --touch-from=$EXPIRY_MINZOOM -s /var/run/renderd.sock < "$DIRTY_TILES_FILENAME"
    fi
    rm -f "$TMP_OSC"
done