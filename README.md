# OSM, OSRM and PostreSQL+postgis containers

This container allows you to set up an OpenStreetMap PNG tile server given a `.osm.pbf` file and OSRM-backend server given a `url osm file`.

## Setting up the server

First set in .env file all necessary credentials and working directory to store apllications data.

Run the PostgreSQL server

    docker-compose up -d postgis

Build OSM container:

    docker-compose build

Next, change URLs in `init_osm_data.sh` file - set links on OSM files for the region that you're interested in.
Also, change OSRM file URL in `.env` file.

Now run script to download OSM file and init state.txt file (it is needed for updating):

    ./init_osm_data.sh


Import OSM data:

    docker-compose up osmimport

It will take some time.


## Running the OSM server

Run the OSM server like this:

    docker-compose up -d osm

Your tiles will now be available at http://localhost:80/tile/{z}/{x}/{y}.png. 


## Preserving rendered tiles

Tiles that have already been rendered will be stored in `${APP_DIR}/tiles/`. 


## Performance tuning


Change, if it is needed, postgre parameters in `./conf/psql_overrides.conf` and restart postgis container.
The import and tile serving processes use 4 threads by default, but this number can be changed by setting the `THREADS` environment variable.


## Updating OSM data

Run inside OSM container:

    sudo -E -u renderer /map-update.sh

or outside:

    docker-compose exec osm sudo -E -u renderer /map-update.sh


## Running the OSRM server

Run the OSRM server like this:

    docker-compose up -d osrm

Wait while import will be complete. You can check osrm container status:

    docker-compose logs osrm


OSRM API available now at: `http://10.5.0.25:5000/route/v1/walking/-75.556521,39.746364;-75.545551,39.747228?overview=false`


## Updating OSRM data

There are 2 identical containers are used for updating OSRM data. Ones per week one of them is deleting and new one is creating.
Containers names are: `osrm` and `osrm2` (see docker-compose.yml file). Iptables nat is using to redirect external `5000` port to actual osrm container.
Script `osrm_update.sh` is using for it.

Set docker-compose working directory (WRKDIR=/srv/gis) in script and add cron job. For example:

    `30 1 * * 5 root /srv/gis/osrm_update.sh osrm osrm2`

(1:30 am every friday)
Use OSRM containers names as arguments for script. Here they are: osrm and osrm2 





