create extension postgis;
create extension pgrouting;

-- basic query
SELECT osm_id, way, ST_Y(ST_Transform(way, 4326)) AS lat,
ST_X(ST_Transform(way, 4326)) AS long
from planet_osm_point
where name = 'Michalská brána';


select osm_id,name, amenity from planet_osm_point
where amenity is not null;


select * from planet_osm_point
where amenity = 'cafe';


select osm_id, name,amenity from planet_osm_point
where amenity = 'cafe';


select osm_id, name, amenity, ST_AsGeoJSON(ST_Transform(way,4326)) as geom from planet_osm_point
where amenity = 'cafe';

SELECT name from planet_osm_point

where  ST_DWithin(st_transform(way,4326)::geography, ST_SetSRID(ST_MakePoint(17.1061116, 48.14498859990289), 4326)::geography,50)
and amenity = 'cafe';


SELECT jsonb_build_object(
  'type',     'FeatureCollection',
  'features', jsonb_agg(feature)
)
FROM (
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
  FROM (
    SELECT name, osm_id, way, "addr:street", "addr:housenumber",operator,website,outdoor_seating, internet_access,smoking,opening_hours FROM planet_osm_point
    where amenity = 'cafe'
    and ST_DWithin(st_transform(way,4326)::geography, ST_SetSRID(ST_MakePoint(17.1061116, 48.14498859990289), 4326)::geography, 200)
  ) inputs
) features;

select row_to_json(fc) FROM ( SELECT 'FeatureCollection' As type, array_to_json(array_agg(f)) As features FROM (SELECT 'Feature' As type , ST_AsGeoJSON(ST_Transform(way,4326))::json As geometry FROM planet_osm_point as R where R.amenity = 'cafe' ) as f ) as fc;

select ways_vertices_pgr.id as vertex_id,planet_osm_point.amenity, planet_osm_point.osm_id, planet_osm_point.name
from planet_osm_point
       LEFT JOIN ways_vertices_pgr ON (planet_osm_point.osm_id = ways_vertices_pgr.osm_id)
where ways_vertices_pgr.id notnull and planet_osm_point.amenity NOTNULL;

SELECT d.seq, d.node, d.edge, d.cost, e.geom AS edge_geom
FROM pgr_dijkstra(
         -- edges
       'SELECT gid AS id, source, target, length AS cost FROM ways',
       -- source node
       (SELECT place_id FROM places WHERE common_name = 'Museum Of Flight'),
       -- target node
       (SELECT place_id FROM places WHERE common_name = 'Benaroya Hall'
                                      AND city_feature = 'General Attractions'),
       FALSE
         ) as d
       LEFT JOIN streets AS e ON d.edge = e.gid
ORDER BY d.seq;

-- select GeoJSON
SELECT ST_AsGeoJSON(ST_UNION(b.the_geom))
-- SELECT seq, edge, rpad(b.the_geom::text,60,' ') AS "the_geom (truncated)"
FROM pgr_dijkstra('
                SELECT gid as id, source, target,
                        length as cost FROM ways',
                  103675, 95222, false
         ) a
       INNER JOIN ways b ON (a.edge = b.gid);



