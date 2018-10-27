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

## My project



**Application description**: Web-based application demonstrating advanced geospatial queries (result visualisation included).

We focused on queries somehow related to student's everyday life in the big city:

1. Find all near-by cafés :coffee: and/or restaurants :ramen: (based either on current position or position chosen by user itself).
2. Find shortest path from dorm to work that includes chosen cafe (mornings are tough and cocaine illegal :pig_nose: ).
3. Earthquake heatmap for Italy (part of everyday life in Italy, sorta).

// other usecases can appear occasionally :bust_in_silhouette: :eyes: 

**Data source**: [Kaggle](https://www.kaggle.com/)

**Technologies used**:

* PgRouting
* Flask
* JS, JQuery, AJAX
* Mapbox GL JS
 
