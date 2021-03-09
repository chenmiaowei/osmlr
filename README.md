# OSMLR segment generation application

OSMLR segments are used as part of the [OTv2 platform](https://github.com/opentraffic/otv2-platform) to associate traffic speeds and volumes with roadways through a stable set of identifiers. This application is used to generate and update OSMLR segments. It's run approximately once a quarter and the resulting tileset of OSMLR segments are posted to Amazon S3.

The code is open-source for contribution -- but the power of OSMLR comes from everyone using a single canonical tileset produced by this program. In other words, it's recommended that you download existing OSMLR segment tiles from S3, rather than run this application yourself to create your own set.

## Using OSMLR segments

- AWS Public Datasets program S3 bucket with OSMLR segments:
  - S3 bucket name: `osmlr`
  - file listings: https://s3.amazonaws.com/osmlr/listing.html
- Related code:
  - [Scripts to download prebuilt OSMLR segment tiles from S3](py/README.md)
  - [OSMLR tile specification](https://github.com/opentraffic/osmlr-tile-spec): Protocol Buffer definition files used by this generator application, as well as consumers of OSMLR segments
- Documentation:
  - [Introduction to OSMLR](docs/intro.md)
  - [Update process](docs/osmlr_updates.md)
- Blog posts:
  - [OSMLR hits a "mile marker" (and joins AWS Public Datasets)](https://mapzen.com/blog/osmlr-released-as-public-dataset/)
  - [Open Traffic technical preview #1: OSMLR segments](https://mapzen.com/blog/open-traffic-osmlr-technical-preview/)
  - [OSMLR traffic segments for the entire planet](https://mapzen.com/blog/osmlr-2nd-technical-preview/)

## Development of this application

### Build Status

[![Build Status](https://travis-ci.org/opentraffic/osmlr.svg?branch=master)](https://travis-ci.org/opentraffic/osmlr)

### Building and Running

To build, install and run on Ubuntu (or other Debian based systems) try the following bash commands:

```bash
#get dependencies
sudo apt-add-repository ppa:kevinkreiser/prime-server -y
sudo add-apt-repository ppa:valhalla-routing/valhalla -y
sudo apt-get update
sudo apt-get install libvalhalla-dev valhalla-bin

#download some data and make tiles out of it
wget YOUR_FAV_PLANET_MIRROR_HERE -O planet.pbf

#get the config and setup for it
valhalla_build_config --mjolnir-tile-dir valhalla_tiles --mjolnir-tile-extract valhalla_tiles.tar --mjolnir-timezone valhalla_tiles/timezones.sqlite --mjolnir-admin valhalla_tiles/admins.sqlite > valhalla.json

#build routing tiles
#TODO: run valhalla_build_admins?
valhalla_build_tiles -c valhalla.json /data-pbf/gcc-states-latest.osm.pbf

#tar it up for running the server
find valhalla_tiles | sort -n | tar cf tiles.tar --no-recursion -T -

#make some osmlr segments
 LD_LIBRARY_PATH=/usr/lib:/usr/local/lib ./osmlr -m 1 -T osmlr_tiles -J osmlr_geojsons valhalla.json

# -j 2 uses two threads for association process (use more or fewer as available cores permit)
valhalla_associate_segments -t ${PWD}/osmlr_tiles -j 2 --config valhalla.json

#rebuild tar with traffic segement associated tiles
find valhalla_tiles | sort -n | tar rf tiles.tar --no-recursion -T -

#Update OSMLR segments.  
This will copy your existing pbf and geojson tiles to their equivalent output directories and update the tiles as needed.  Features will be removed add added from the feature collection in the geojson tiles.  Moreover, segements that no longer exist in the valhalla tiles will be cleared and a deletion date will be set. 
./osmlr -u -m 2 -f 256 -P ./<old_tiles>/pbf -G ./<old_tiles>/geojson -J ./<new_tiles>/geojson -T ./<new_tiles>/pbf --config valhalla.json

#HAVE FUN!
```



## Docker
```
docker build -t swr.ap-southeast-3.myhuaweicloud.com/gomap/opentraffic-osmlr:latest .
docker push swr.ap-southeast-3.myhuaweicloud.com/gomap/capistrano:latest


docker run -it swr.ap-southeast-3.myhuaweicloud.com/gomap/opentraffic-osmlr:latest
docker run --volume ${PWD}:/data swr.ap-southeast-3.myhuaweicloud.com/gomap/opentraffic-osmlr:latest ls /data
docker run --volume ~/Documents/Docker/osmlr-data:/data swr.ap-southeast-3.myhuaweicloud.com/gomap/opentraffic-osmlr:latest ls /data

#get the config and setup for it
docker run --volume ${PWD}:/data swr.ap-southeast-3.myhuaweicloud.com/gomap/opentraffic-osmlr:latest valhalla_build_config --mjolnir-tile-dir /data/valhalla_tiles --mjolnir-tile-extract /data/valhalla_tiles.tar --mjolnir-timezone /data/valhalla_tiles/timezones.sqlite --mjolnir-admin /data/valhalla_tiles/admins.sqlite > valhalla.json
docker run --volume  ~/Documents/Docker/osmlr-data:/data swr.ap-southeast-3.myhuaweicloud.com/gomap/opentraffic-osmlr:latest valhalla_build_config --mjolnir-tile-dir /data/valhalla_tiles --mjolnir-tile-extract /data/valhalla_tiles.tar --mjolnir-timezone /data/valhalla_tiles/timezones.sqlite --mjolnir-admin /data/valhalla_tiles/admins.sqlite > ~/Documents/Docker/osmlr-data/valhalla.json

#build routing tiles
#TODO: run valhalla_build_admins?
docker run --volume ${PWD}:/data swr.ap-southeast-3.myhuaweicloud.com/gomap/opentraffic-osmlr:latest  valhalla_build_tiles -c /data/valhalla.json /data/uae.osm.pbf

rm -f ~/Documents/Docker/osmlr-data/uae.osm.pbf
docker run --rm -i --volume ~/Documents/Docker/osmlr-data:/osm mediagis/osmtools osmconvert /osm/uae.osm --out-pbf > ~/Documents/Docker/osmlr-data/uae.osm.pbf
docker run --volume ~/Documents/Docker/osmlr-data:/data swr.ap-southeast-3.myhuaweicloud.com/gomap/opentraffic-osmlr:latest  valhalla_build_tiles -c /data/valhalla.json /data/uae.osm.pbf

#tar it up for running the server
cd ~/Documents/Docker/osmlr-data
find ./valhalla_tiles | sort -n | tar cf tiles.tar --no-recursion -T -

#make some osmlr segments
docker run --volume ${PWD}:/data swr.ap-southeast-3.myhuaweicloud.com/gomap/opentraffic-osmlr:latest osmlr -m 1 -T /data/osmlr_tiles -J /data/osmlr_geojsons /data/valhalla.json
docker run --volume ~/Documents/Docker/osmlr-data:/data swr.ap-southeast-3.myhuaweicloud.com/gomap/opentraffic-osmlr:latest osmlr -m 1 -T /data/osmlr_tiles -J /data/osmlr_geojsons /data/valhalla.json

# -j 2 uses two threads for association process (use more or fewer as available cores permit)
docker run --volume ${PWD}:/data swr.ap-southeast-3.myhuaweicloud.com/gomap/opentraffic-osmlr:latest valhalla_associate_segments -t /data/osmlr_tiles -j 2 --config /data/valhalla.json
docker run --volume ~/Documents/Docker/osmlr-data:/data swr.ap-southeast-3.myhuaweicloud.com/gomap/opentraffic-osmlr:latest valhalla_associate_segments -t /data/osmlr_tiles -j 2 --config /data/valhalla.json

#rebuild tar with traffic segement associated tiles
find ./valhalla_tiles | sort -n | tar rf tiles.tar --no-recursion -T -

#Update OSMLR segments.  
This will copy your existing pbf and geojson tiles to their equivalent output directories and update the tiles as needed.  Features will be removed add added from the feature collection in the geojson tiles.  Moreover, segements that no longer exist in the valhalla tiles will be cleared and a deletion date will be set. 
docker run --volume ${PWD}:/data swr.ap-southeast-3.myhuaweicloud.com/gomap/opentraffic-osmlr:latest osmlr -u -m 2 -f 256 -P /data/<old_tiles>/pbf -G /data/<old_tiles>/geojson -J /data/<new_tiles>/geojson -T /data/<new_tiles>/pbf --config /data/valhalla.json
docker run --volume ~/Documents/Docker/osmlr-data:/data swr.ap-southeast-3.myhuaweicloud.com/gomap/opentraffic-osmlr:latest osmlr -u -m 2 -f 256 -P /data/<old_tiles>/pbf -G /data/<old_tiles>/geojson -J /data/<new_tiles>/geojson -T /data/<new_tiles>/pbf --config /data/valhalla.json

#HAVE FUN!
```