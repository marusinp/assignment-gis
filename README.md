# General course assignment

Build a map-based application, which lets the user see geo-based data on a map and filter/search through it in a meaningfull way. Specify the details and build it in your language of choice. The application should have 3 components:

1. Custom-styled background map, ideally built with [mapbox](http://mapbox.com). Hard-core mode: you can also serve the map tiles yourself using [mapnik](http://mapnik.org/) or similar tool.
2. Local server with [PostGIS](http://postgis.net/) and an API layer that exposes data in a [geojson format](http://geojson.org/).
3. The user-facing application (web, android, ios, your choice..) which calls the API and lets the user see and navigate in the map and shows the geodata. You can (and should) use existing components, such as the Mapbox SDK, or [Leaflet](http://leafletjs.com/).

## Example projects

- Showing nearby landmarks as colored circles, each type of landmark has different circle color and the more interesting the landmark is, the bigger the circle. Landmarks are sorted in a sidebar by distance to the user. It is possible to filter only certain landmark types (e.g., castles).

- Showing bicykle roads on a map. The roads are color-coded based on the road difficulty. The user can see various lists which help her choose an appropriate road, e.g. roads that cross a river, roads that are nearby lakes, roads that pass through multiple countries, etc.

## Data sources

- [Open Street Maps](https://www.openstreetmap.org/)
- [GEOFABRIK](https://www.geofabrik.de/)

## My project



**Application description**: Web-based application demonstrating advanced geospatial queries (result visualisation included).

We focused on queries somehow related to everyday life in the big city:

### List of usecases covered:

// other usecases may appear occasionally :bust_in_silhouette: :eyes: 


**List of datasets:** 

* [Italy's Earthquakes](https://www.kaggle.com/blackecho/italy-earthquakes) - data about the earthquakes that hit Italy between August and November 2016.
* [London Police Records](https://www.kaggle.com/sohier/london-police-records/) - complete snapshot of crime, outcome, and stop and search data, as held by the Home Office from late 2014 through mid 2017 for London, both the greater metro and the city.
 
**Technologies & tools used:**

* [PgRouting](https://pgrouting.org/) - additional layer on the top of PostGIS for routing 
* [Flask](http://flask.pocoo.org/) - backend
* JS, JQuery, AJAX, [Mapbox GL JS API](https://www.mapbox.com/mapbox-gl-js/api/) (v0.50.0) - frontend
* [osm2pgsql](https://github.com/openstreetmap/osm2pgsql) - import tool for loading OpenStreetMap data into PostgreSQL
* [osm2pgrouting](https://github.com/pgRouting/osm2pgrouting)- import tool for OpenStreetMap data to pgRouting database.

### Queries presented
 
#### 1. Display nearby cafés

![](uc_1.gif)

Insert distance (in meters). After submission you'll see all nearby cafés within inserted radius. 
You can then select any of them for more information by clicking on the marker.

**Query:**
```postgresql
with poi as (
	SELECT name, osm_id, way, "addr:street", "addr:housenumber",operator,website,outdoor_seating, internet_access,smoking,opening_hours FROM planet_osm_point
    where amenity = 'cafe'
    and ST_DWithin(st_transform(way,4326)::geography, ST_SetSRID(ST_MakePoint(lng, lat), 4326)::geography, radius)
)
SELECT jsonb_build_object(
  'type',     'FeatureCollection',
  'features', jsonb_agg(feature)
) from (
SELECT jsonb_build_object(
    'type',       'Feature',
    'id',         osm_id,
    'geometry',   ST_AsGeoJSON(ST_Transform(way,4326))::jsonb,
    'properties', jsonb_strip_nulls(jsonb_build_object(
   		'name', name,
    	'operator', operator,
    	'opening_hours', opening_hours,
    	'website', website,
    	'outdoor_seating', outdoor_seating,
    	'internet_access', internet_access,
    	'smoking', smoking,
    	'addr:street', "addr:street",
    	'addr:housenumber', "addr:housenumber",
    	'internet_access', internet_access
  ))
  ) AS feature
  FROM poi
  ) features;
``` 


