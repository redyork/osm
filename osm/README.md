# openstreetmap-tile-server

## Setting up the server


If the container exits without errors, then your data has been successfully imported and you are now ready to run the tile server.

## Running the server

Run the server like this:

    docker run -p 80:80 -v openstreetmap-data:/var/lib/postgresql/10/main -d overv/openstreetmap-tile-server run

Your tiles will now be available at http://localhost:80/tile/{z}/{x}/{y}.png. If you open `leaflet-demo.html` in your browser, you should be able to see the tiles served by your own machine. Note that it will initially quite a bit of time to render the larger tiles for the first time.


