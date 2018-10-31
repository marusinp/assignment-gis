create extension postgis;
create extension pgrouting;

-- basic query
SELECT osm_id, way, ST_Y(ST_Transform(way, 4326)) AS lat, ST_X(ST_Transform(way, 4326)) AS long
from planet_osm_point
where name = 'Michalská brána';


select osm_id, name, amenity
from planet_osm_point
where amenity is not null;

------

select *
from planet_osm_point
where amenity = 'cafe';

-----

select osm_id, name, amenity
from planet_osm_point
where amenity = 'cafe';

-----

select osm_id, name, amenity, ST_AsGeoJSON(ST_Transform(way, 4326)) as geom
from planet_osm_point
where amenity = 'cafe';

-----

SELECT name
from planet_osm_point

		----

where ST_DWithin(st_transform(way, 4326) :: geography,
								 ST_SetSRID(ST_MakePoint(17.1061116, 48.14498859990289), 4326) :: geography, 50)
	and amenity = 'cafe';

----

SELECT jsonb_build_object(
				 'type', 'FeatureCollection',
				 'features', jsonb_agg(feature)
					 )
FROM (SELECT jsonb_build_object(
							 'type', 'Feature',
							 'id', osm_id,
							 'geometry', ST_AsGeoJSON(ST_Transform(way, 4326)) :: jsonb,
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
			FROM (SELECT name,
									 osm_id,
									 way,
									 "addr:street",
									 "addr:housenumber",
									 operator,
									 website,
									 outdoor_seating,
									 internet_access,
									 smoking,
									 opening_hours
						FROM planet_osm_point
						where amenity = 'cafe'
							and ST_DWithin(st_transform(way, 4326) :: geography,
														 ST_SetSRID(ST_MakePoint(17.1061116, 48.14498859990289), 4326) :: geography,
														 200)) inputs) features;

------

-- Startup Cost: 0.00
-- Total Cost: 32853.76

explain (format yaml, analyze true) SELECT name,
																					 osm_id,
																					 way,
																					 "addr:street",
																					 "addr:housenumber",
																					 operator,
																					 website,
																					 outdoor_seating,
																					 internet_access,
																					 smoking,
																					 opening_hours
																		FROM planet_osm_point
																		where amenity = 'cafe'
																			and ST_DWithin(st_transform(way, 4326) :: geography,
																										 ST_SetSRID(ST_MakePoint(17.1061116, 48.14498859990289), 4326) :: geography,
																										 5000);

CREATE INDEX gist_geog_point
	ON planet_osm_point
	USING GIST (geography(st_transform(way, 4326)));

-- Startup Cost: 737.51
-- Total Cost: 8113.15
explain (format yaml, analyze true) SELECT name,
																					 osm_id,
																					 way,
																					 "addr:street",
																					 "addr:housenumber",
																					 operator,
																					 website,
																					 outdoor_seating,
																					 internet_access,
																					 smoking,
																					 opening_hours
																		FROM planet_osm_point
																		where amenity = 'cafe'
																			and ST_DWithin(st_transform(way, 4326) :: geography,
																										 ST_SetSRID(ST_MakePoint(17.1061116, 48.14498859990289), 4326) :: geography,
																										 5000);

drop INDEX gist_geog_point;

-----

with poi as (SELECT name,
										osm_id,
										way,
										"addr:street",
										"addr:housenumber",
										operator,
										website,
										outdoor_seating,
										internet_access,
										smoking,
										opening_hours
						 FROM planet_osm_point
						 where amenity = 'cafe'
							 and ST_DWithin(st_transform(way, 4326) :: geography,
															ST_SetSRID(ST_MakePoint(17.1061116, 48.14498859990289), 4326) :: geography, 200))
SELECT jsonb_build_object(
				 'type', 'FeatureCollection',
				 'features', jsonb_agg(feature)
					 )
from (SELECT jsonb_build_object(
							 'type', 'Feature',
							 'id', osm_id,
							 'geometry', ST_AsGeoJSON(ST_Transform(way, 4326)) :: jsonb,
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
			FROM poi) features;

-------

select row_to_json(fc)
FROM (SELECT 'FeatureCollection' As type, array_to_json(array_agg(f)) As features
			FROM (SELECT 'Feature' As type, ST_AsGeoJSON(ST_Transform(way, 4326)) :: json As geometry
						FROM planet_osm_point as R
						where R.amenity = 'cafe') as f) as fc;

select ways_vertices_pgr.id as vertex_id, planet_osm_point.amenity, planet_osm_point.osm_id, planet_osm_point.name
from planet_osm_point
			 JOIN ways_vertices_pgr ON (planet_osm_point.osm_id = ways_vertices_pgr.osm_id)
where ways_vertices_pgr.id = 121070;

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


CREATE TABLE italy
(
	id        SERIAL PRIMARY KEY,
	latitude  real,
	longitude real,
	depth_km  real,
	magnitude real
);

drop table italy;


COPY italy (latitude, longitude, depth_km, magnitude)
FROM '/Users/pmarusin/Downloads/italy-s-earthquakes.csv' DELIMITER ',' CSV HEADER;

alter table italy
	add column geom geometry(Point, 4326);
update italy
set geom = st_SetSrid(st_MakePoint(longitude, latitude), 4326);

SELECT jsonb_build_object(
				 'type', 'FeatureCollection',
				 'features', jsonb_agg(feature)
					 )
FROM (SELECT jsonb_build_object(
							 'type', 'Feature',
							 'geometry', ST_AsGeoJSON(ST_Transform(geom, 4326)) :: jsonb,
							 'properties', jsonb_strip_nulls(jsonb_build_object(
																								 'magnitude', magnitude
																									 ))
								 ) AS feature
			FROM (SELECT magnitude, geom FROM italy) inputs) features;

-- with square_point as (
select osm_id, name, ST_Transform(way, 4326)
from planet_osm_polygon as polygon

where lower(name) like '%námestie%';

----

SELECT x.path_id,
			 x.path_seq,
			 COALESCE(s.osm_id|| ' - ' || t.osm_id, 'Total Trip') as route,
			 CASE
				 WHEN edge = -1 THEN agg_cost
				 ELSE NULL END                                      AS "total_cost(distance)"
FROM pgr_ksp(
			 'SELECT gid as id, source, target, length AS cost FROM ways',
			 (103675),
			 (95222),
			 1,
			 directed := FALSE
				 ) as x
			 LEFT JOIN ways AS r ON x.edge = r.gid
			 LEFT JOIN ways_vertices_pgr AS s ON r.source = s.id
			 LEFT JOIN ways_vertices_pgr AS t ON r.target = t.id

ORDER BY x.path_id, x.path_seq;

-----

select ways.gid as edge_id, polygon.osm_id, polygon.amenity, polygon.name
from planet_osm_polygon as polygon
			 JOIN ways ON (polygon.osm_id = ways.osm_id);

----

select *
from planet_osm_point
where osm_id = 2001099710;

-----
select vertices.id as vertex_id, point.osm_id, point.amenity, point.name
from planet_osm_point as point
			 JOIN ways_vertices_pgr as vertices ON (point.osm_id = vertices.osm_id)
where lower(name) = 'yeme'
limit 1;
----


select vertices.id as vertex_id, point.osm_id, point.amenity, point.name
from planet_osm_point as point
			 JOIN ways_vertices_pgr as vertices ON (point.osm_id = vertices.osm_id)
where point.name like '%námestie%';

----
with src as (select vertices.id as src_id, point.osm_id, point.amenity, point.name
						 from planet_osm_point as point
										JOIN ways_vertices_pgr as vertices ON (point.osm_id = vertices.osm_id)
						 where lower(name) = 'lekáreň sv. michala'
						 limit 1),
		 stop as (select vertices.id as stop_id, point.osm_id, point.amenity, point.name
							from planet_osm_point as point
										 JOIN ways_vertices_pgr as vertices ON (point.osm_id = vertices.osm_id)
							where lower(name) = 'santal'
							limit 1),
		 dst as (select vertices.id as dst_id, point.osm_id, point.amenity, point.name
						 from planet_osm_point as point
										JOIN ways_vertices_pgr as vertices ON (point.osm_id = vertices.osm_id)
						 where lower(name) = 'slovenská sporiteľňa'
						 limit 1)
select ST_AsGeoJSON(st_union((merged_route.the_geom)))
from (SELECT ways.the_geom
			from pgr_dijkstra('SELECT gid as id, source, target,
							 length as cost FROM ways',
												(select src_id from src),
												(select stop_id from stop),
												directed := false
							 ) src_stop_dij
						 JOIN ways ON (src_stop_dij.edge = ways.gid)
			--         order by src_stop_dij.seq
			union
			SELECT ways.the_geom
			from pgr_dijkstra('
                SELECT gid as id, source, target,
                        length as cost FROM ways',
												(select stop_id from stop),
												(select dst_id from dst),
												directed := false
							 ) stop_dst_dij
						 JOIN ways ON (stop_dst_dij.edge = ways.gid)) merged_route;
--         order by stop_dst_dij.seq;


----




SELECT ST_AsGeoJSON(ST_UNION(b.the_geom))
		-- SELECT seq, edge, rpad(b.the_geom::text,60,' ') AS "the_geom (truncated)"
FROM pgr_dijkstra('
                SELECT gid as id, source, target,
                        length as cost FROM ways',
									--                   103675, 95222,
									103675, 121070,
									directed := false
				 ) a
			 JOIN ways b ON (a.edge = b.gid);

----


----



