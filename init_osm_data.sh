#!/bin/bash

source .env
#http://download.geofabrik.de/europe/great-britain/england/greater-london-latest.osm.pbf

wget http://download.geofabrik.de/europe/great-britain/england/greater-london-latest.osm.pbf -O $APP_DIR/import/data.osm.pbf
wget http://download.geofabrik.de/europe/great-britain/england/greater-london-updates/state.txt -O $APP_DIR/import/state.txt

echo "baseUrl=http://download.geofabrik.de/europe/great-britain/england/greater-london-updates
maxInterval=3600
" > $APP_DIR/import/configuration.txt




