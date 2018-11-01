#!/usr/bin/env bash

# Import .osm to pgsql:
osm2pgsql -U pmarusin -d gis  -H localhost map.osm

# create routing network
osm2pgrouting -f map.osm -h localhost -U pmarusin -d gis -p 5432  —conf=osm2pgrouting/mapconfig.xml

#edited style location:
#/usr/local/Cellar/osm2pgsql/0.96.0/share/osm2pgsql/default.style