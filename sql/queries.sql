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


SELECT jsonb_build_object(
				 'type', 'FeatureCollection',
				 'features', jsonb_agg(feature)
					 )
FROM (SELECT jsonb_build_object(
							 'type', 'Feature',
							 'geometry', ST_AsGeoJSON(ST_Transform(way, 4326)) :: jsonb,
							 'properties', jsonb_strip_nulls(jsonb_build_object(
																								 'name', name
																									 ))
								 ) AS feature
			FROM (select st_transform(point.way, 4326) as way,
									 vertices.id                   as vertex_id,
									 point.osm_id,
									 point.amenity,
									 point.name
						from planet_osm_point as point
									 JOIN ways_vertices_pgr as vertices ON (point.osm_id = vertices.osm_id)
						where lower(name) = 'lekáreň sv. michala'
							 or lower(name) = 'santal'
							 or lower(name) = 'slovenská sporiteľňa'

						limit 3) inputs) features;


select st_transform(point.way, 4326) as way, vertices.id as vertex_id, point.osm_id, point.amenity, point.name
from planet_osm_point as point
			 JOIN ways_vertices_pgr as vertices ON (point.osm_id = vertices.osm_id)
where lower(name) = 'lekáreň sv. michala'
	 or lower(name) = 'santal'
	 or lower(name) = 'slovenská sporiteľňa'

limit 3;

with src as (select st_transform(point.way, 4326) as way,
																												vertices.id                   as src_id,
																												point.osm_id,
																												point.amenity,
																												point.name
																								 from planet_osm_point as point
																												JOIN ways_vertices_pgr as vertices
																													ON (point.osm_id = vertices.osm_id)
																								 where lower(name) =  'olive and lemon'
																								 limit 1),
																				 stop as (select st_transform(point.way, 4326) as way,
																												 vertices.id                   as stop_id,
																												 point.osm_id,
																												 point.amenity,
																												 point.name
																									from planet_osm_point as point
																												 JOIN ways_vertices_pgr as vertices
																													 ON (point.osm_id = vertices.osm_id)
																									where lower(name) = 'tower of london'
																									limit 1),
																				 dst as (select st_transform(point.way, 4326) as way,
																												vertices.id                   as dst_id,
																												point.osm_id,
																												point.amenity,
																												point.name
																								 from planet_osm_point as point
																												JOIN ways_vertices_pgr as vertices
																													ON (point.osm_id = vertices.osm_id)
																								 where lower(name) = 'natural history museum / cromwell road'
																								 limit 1)
																		select ST_AsGeoJSON(st_union((merged_route.the_geom))),
																					 st_asgeojson(st_union((src.way))),
																					 st_asgeojson(st_union((stop.way))),
																					 st_asgeojson(st_union(dst.way))
																		from (SELECT ways.the_geom
																					from pgr_dijkstra('SELECT gid as id, source, target,
							 length as cost FROM ways',
																														(select src_id from src),
																														(select stop_id from stop),
																														directed := false
																									 ) src_stop_dij
																								 JOIN ways ON (src_stop_dij.edge = ways.gid)
																					union
																					SELECT ways.the_geom
																					from pgr_dijkstra('
                SELECT gid as id, source, target,
                        length as cost FROM ways',
																														(select stop_id from stop),
																														(select dst_id from dst),
																														directed := false
																									 ) stop_dst_dij
																								 JOIN ways ON (stop_dst_dij.edge = ways.gid)) merged_route,
																				 src,
																				 stop,
																				 dst;
---

select vertices.id as vertex_id, point.osm_id, point.amenity, point.name
from planet_osm_point as point
			 JOIN ways_vertices_pgr as vertices ON (point.osm_id = vertices.osm_id)
where lower(name) like '%centre%';

---

select vertices.id as vertex_id, point.osm_id, point.amenity, point.name
from planet_osm_point as point
			 JOIN ways_vertices_pgr as vertices ON (point.osm_id = vertices.osm_id)
where lower(name) = 'yeme'
limit 1;
----



select vertices.id as vertex_id, point.osm_id, point.amenity, point.name
from planet_osm_point as point
			 JOIN ways_vertices_pgr as vertices ON (point.osm_id = vertices.osm_id)
where point.name is not null and amenity is not null;

----



explain (format yaml, analyze true) select vertices.id as src_id, point.osm_id, point.amenity, point.name
																		from planet_osm_point as point
																					 JOIN ways_vertices_pgr as vertices ON (point.osm_id = vertices.osm_id)
																		where lower(name) = 'lekáreň sv. michala'
																		limit 1;
-- Startup Cost: 0.00
-- Total Cost: 2178.31
create index index_points_on_lower_name
	on planet_osm_point (lower(name));

-- Startup Cost: 0.42
-- Total Cost: 1327.26
explain (format yaml, analyze true) select vertices.id as src_id, point.osm_id, point.amenity, point.name
																		from planet_osm_point as point
																					 JOIN ways_vertices_pgr as vertices ON (point.osm_id = vertices.osm_id)
																		where lower(name) = 'lekáreň sv. michala'
																		limit 1;

drop index index_points_on_lower_name;

CREATE INDEX gist_geom_point
	ON planet_osm_point
	USING GIST (geography(st_transform(way, 4326)));

-- create index index_points_on_lower_name on planet_osm_point (lower(name));

-- drop index index_points_on_lower_name;

-- s indexom index_points_on_lower_name: 	Startup Cost: 12013.95
--     																		Total Cost: 12016.46

-- bez indexu index_points_on_lower_name 	Startup Cost: 12019.23
--     																		Total Cost: 12021.74
-- eeeeh

explain (format yaml, analyze true) with src as (select st_transform(point.way, 4326) as way,
																												vertices.id                   as src_id,
																												point.osm_id,
																												point.amenity,
																												point.name
																								 from planet_osm_point as point
																												JOIN ways_vertices_pgr as vertices
																													ON (point.osm_id = vertices.osm_id)
																								 where lower(name) = 'lekáreň sv. michala'
																								 limit 1),
																				 stop as (select st_transform(point.way, 4326) as way,
																												 vertices.id                   as stop_id,
																												 point.osm_id,
																												 point.amenity,
																												 point.name
																									from planet_osm_point as point
																												 JOIN ways_vertices_pgr as vertices
																													 ON (point.osm_id = vertices.osm_id)
																									where lower(name) = 'santal'
																									limit 1),
																				 dst as (select st_transform(point.way, 4326) as way,
																												vertices.id                   as dst_id,
																												point.osm_id,
																												point.amenity,
																												point.name
																								 from planet_osm_point as point
																												JOIN ways_vertices_pgr as vertices
																													ON (point.osm_id = vertices.osm_id)
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
-- geom index uz existuje a indexy na ways.source a ways.target nemaju vplyv na performance
CREATE INDEX source_idx
	ON ways (source);
CREATE INDEX target_idx
	ON ways (target);
-- CREATE INDEX geom_idx ON ways USING GIST(the_geom);

drop INDEX source_idx;
drop INDEX target_idx;
-- drop INDEX geom_idx;


with src as (select vertices.id as src_id, point.osm_id, point.amenity, point.name, point.way
						 from planet_osm_point as point
										JOIN ways_vertices_pgr as vertices ON (point.osm_id = vertices.osm_id)
						 where lower(name) = 'lekáreň sv. michala'
						 limit 1),
		 stop as (select vertices.id as stop_id, point.osm_id, point.amenity, point.name, point.way
							from planet_osm_point as point
										 JOIN ways_vertices_pgr as vertices ON (point.osm_id = vertices.osm_id)
							where lower(name) = 'santal'
							limit 1),
		 dst as (select vertices.id as dst_id, point.osm_id, point.amenity, point.name, point.way
						 from planet_osm_point as point
										JOIN ways_vertices_pgr as vertices ON (point.osm_id = vertices.osm_id)
						 where lower(name) = 'slovenská sporiteľňa'
						 limit 1),
		 radius as (select greatest(st_distance_sphere(st_transform(src.way, 4326), st_transform(stop.way, 4326)),
																st_distance_sphere(st_transform(src.way, 4326), st_transform(dst.way, 4326)),
																st_distance_sphere(st_transform(stop.way, 4326),
																									 st_transform(dst.way, 4326))) as bb_radius
								from src,
										 stop,
										 dst)
		-- SELECT 'SELECT gid as id, source, target, length as cost
		-- FROM ways
		-- where ST_DWithin(st_transform(ways.the_geom, 4326) :: geography,
		-- 								 st_transform('|| 9||', 4326) :: geography,
		-- 								 ',||8* 2||,')';

		-- select 'Value: ' || 42;
SELECT gid as id, source, target, length as cost
FROM ways,
		 stop,
		 radius
where ST_DWithin(st_transform(ways.the_geom, 4326) :: geography,
								 st_transform(stop.way, 4326) :: geography,
								 radius.bb_radius * 2);

----

 with src as (select vertices.id as src_id,
																												point.osm_id,
																												point.amenity,
																												point.name,
																												point.way
																								 from planet_osm_point as point
																												JOIN ways_vertices_pgr as vertices
																													ON (point.osm_id = vertices.osm_id)
																								 where lower(name) = 'lekáreň sv. michala'
																								 limit 1),
																				 stop as (select vertices.id as stop_id,
																												 point.osm_id,
																												 point.amenity,
																												 point.name,
																												 point.way
																									from planet_osm_point as point
																												 JOIN ways_vertices_pgr as vertices
																													 ON (point.osm_id = vertices.osm_id)
																									where lower(name) = 'santal'
																									limit 1),
																				 dst as (select vertices.id as dst_id,
																												point.osm_id,
																												point.amenity,
																												point.name,
																												point.way
																								 from planet_osm_point as point
																												JOIN ways_vertices_pgr as vertices
																													ON (point.osm_id = vertices.osm_id)
																								 where lower(name) = 'slovenská sporiteľňa'
																								 limit 1),
																				 radius as (select greatest(st_distance_sphere(st_transform(src.way, 4326),
																																											 st_transform(stop.way, 4326)),
																																		st_distance_sphere(st_transform(src.way, 4326),
																																											 st_transform(dst.way, 4326)),
																																		st_distance_sphere(st_transform(stop.way, 4326),
																																											 st_transform(dst.way, 4326))) as bb_radius
																										from src,
																												 stop,
																												 dst)
																		select ST_AsGeoJSON(st_union((merged_route.the_geom)))
																		from (SELECT ways.the_geom
																					from pgr_dijkstra('SELECT gid as id, source, target, length as cost
FROM ways,
		 stop,
		 radius
where ST_DWithin(st_transform(ways.the_geom, 4326) :: geography,
								 st_transform(stop.way, 4326) :: geography,
								 radius.bb_radius * 2)',
																														(select src_id from src),
																														(select stop_id from stop),
																														directed := false
																									 ) src_stop_dij
																								 JOIN ways ON (src_stop_dij.edge = ways.gid)
																					--         order by src_stop_dij.seq
																					union
																					SELECT ways.the_geom
																					from pgr_dijkstra('
                SELECT gid as id, source, target, length as cost
FROM ways,
		 stop,
		 radius
where ST_DWithin(st_transform(ways.the_geom, 4326) :: geography,
								 st_transform(stop.way, 4326) :: geography,
								 radius.bb_radius * 2)',
																														(select stop_id from stop),
																														(select dst_id from dst),
																														directed := false
																									 ) stop_dst_dij
																								 JOIN ways ON (stop_dst_dij.edge = ways.gid)) merged_route;

---
-- london-db analysis
select vertices.id as vertex_id, point.osm_id, point.amenity, point.name
from planet_osm_polygon as point
			 JOIN ways_vertices_pgr as vertices ON (point.osm_id = vertices.osm_id);
-- where point.amenity = 'cafe';

--- create crime_records table

drop table crime_records;

CREATE TABLE crime_records
(
	id                    SERIAL PRIMARY KEY,
	longitude             real,
	latitude              real,
	location              varchar(100),
	crime_type            varchar(100),
	last_outcome_category varchar(100)
);

COPY crime_records (longitude, latitude, location, crime_type, last_outcome_category)
FROM '/Users/pmarusin/Downloads/london-police-records/london-street-edit.csv' DELIMITER ',' CSV HEADER;

alter table crime_records
	add column geom geometry(Point, 4326);

update crime_records
set geom = st_SetSrid(st_MakePoint(longitude, latitude), 4326);

delete
from crime_records
where location = 'No Location';

select count(*)
from crime_records
where location = 'No Location';

----

select count(*)
from crime_records;

----


SELECT *
FROM crime_records
WHERE crime_records IS NULL;

-- visualisation test

with cafes as (select osm_id, name, st_transform(way, 4326) as way
							 from planet_osm_point
							 where planet_osm_point.amenity = 'cafe'
								 and name is not null
							 limit 10)
SELECT jsonb_build_object(
				 'type', 'FeatureCollection',
				 'features', jsonb_agg(feature)
					 )
FROM (SELECT jsonb_build_object(
							 'type', 'Feature',
							 'geometry', ST_AsGeoJSON(ST_Transform(geom, 4326)) :: jsonb,
							 'properties', jsonb_strip_nulls(jsonb_build_object(
																								 'crime_type', crime_type,
																								 'crime_type_count', crime_type_count
																								 -- 																								 'last_outcome_category', last_outcome_category
																									 ))
								 ) AS feature
			FROM (SELECT crime_records.geom, crime_type, count(crime_type) as crime_type_count
						FROM crime_records
									 right join cafes
										 on ST_DWithin((way) :: geography, st_transform(crime_records.geom, 4326) :: geography, 200)
						where crime_type = 'Drugs'
						group by crime_records.geom, crime_type
-- 					 SELECT geom, crime_type
					 -- 						FROM crime_records
					 -- 						where crime_type = 'Violence and sexual offences'
					 -- 						limit 99999
					 --
					 ) inputs) features;

------
--bez indexu: 	Startup Cost: 11370231.18
--     					Total Cost: 11370231.32

-- s indexom: Startup Cost: 9048.99
--     				Total Cost: 9049.13


CREATE INDEX gist_geog_crime_records
	ON crime_records
	USING GIST (geography(st_transform(geom, 4326)));

drop index gist_geog_crime_records;

-----

select st_transform(way, 4326) as geom
from planet_osm_polygon
where name = 'London Borough of Camden';

select st_transform(way, 4326)
from planet_osm_polygon
where name = 'City of Westminster';

select st_transform(way, 4326), *
from planet_osm_polygon
where lower(name) like '%lambeth%';

select st_transform(way, 4326)
from planet_osm_polygon
where name = 'London Borough of Lambeth';

--------

CREATE INDEX if not exists gist_geom_crime_records
	ON crime_records
	USING GIST (st_transform(geom, 4326));

-- drop index gist_geom_crime_records;

-- bez indexu
-- Startup Cost: 2448581.93
--     Total Cost: 2448636.21

-- s indexom: Startup Cost: 48097.96
--     Total Cost: 48152.24

explain (format yaml, analyze true)

with borough as (select st_transform(way, 4326) as geom
								 from planet_osm_polygon
								 where name = 'London Borough of Lambeth')
SELECT crime_records.geom, count(crime_type) as crime_type_count
FROM crime_records
			 join borough on st_contains(borough.geom, st_transform(crime_records.geom, 4326))
group by crime_records.geom;

-----


with borough as (select st_transform(way, 4326) as geom
								 from planet_osm_polygon
								 where name = 'London Borough of Lambeth')
SELECT jsonb_build_object(
				 'type', 'FeatureCollection',
				 'features', jsonb_agg(feature)
					 )
FROM (SELECT jsonb_build_object(
							 'type', 'Feature',
							 'geometry', ST_AsGeoJSON(ST_Transform(geom, 4326)) :: jsonb,
							 'properties', jsonb_strip_nulls(jsonb_build_object(
																								 'crime_type', crime_type,
																								 'crime_type_count', crime_type_count
																									 ))
								 ) AS feature
			FROM (SELECT crime_records.geom, crime_type, count(crime_type) as crime_type_count
						FROM crime_records
									 join borough on st_contains(borough.geom, st_transform(crime_records.geom, 4326))
						where crime_type = 'Robbery'
						group by crime_records.geom, crime_type) inputs) features;

------

with borough as (select st_transform(way, 4326) as geom
								 from planet_osm_polygon
								 where name = 'London Borough of Lambeth')
SELECT jsonb_build_object(
				 'type', 'FeatureCollection',
				 'features', jsonb_agg(feature)
					 )
FROM (SELECT jsonb_build_object(
							 'type', 'Feature',
							 'geometry', ST_AsGeoJSON(ST_Transform(geom, 4326)) :: jsonb,
							 'properties', jsonb_strip_nulls(jsonb_build_object(
																								 'crime_type', crime_type,
																								 'crime_type_count', crime_type_count
																									 ))
								 ) AS feature
			FROM (with borough as (select st_transform(way, 4326) as geom
														 from planet_osm_polygon
														 where name = 'London Borough of Lambeth')
			SELECT crime_records.geom, crime_type, count(crime_type) as crime_type_count
			FROM crime_records
						 join borough on st_contains(borough.geom, st_transform(crime_records.geom, 4326))
			group by crime_records.geom, crime_type) inputs) features;

with borough as (select st_transform(way, 4326) as geom
								 from planet_osm_polygon
								 where name = 'London Borough of Lambeth')
SELECT crime_records.geom, crime_type, count(crime_type) as crime_type_count
FROM crime_records
			 join borough on st_contains(borough.geom, st_transform(crime_records.geom, 4326))
group by crime_records.geom, crime_type;
----


with river_thames as (select st_union(way) as way from planet_osm_line where waterway = 'river'
																																				 and name = 'River Thames')
SELECT jsonb_build_object(
				 'type', 'FeatureCollection',
				 'features', jsonb_agg(feature)
					 )
FROM (SELECT jsonb_build_object(
							 'type', 'Feature',
							 'geometry', ST_AsGeoJSON(ST_Transform(geom, 4326)) :: jsonb,
							 'properties', jsonb_strip_nulls(jsonb_build_object(
																								 'name', name,
																								 'len', len
																									 )
									 )
								 ) AS feature
			FROM (select (array_agg(line.way)) [ 1 ]                                             as geom,
									 line.name,
									 (array_agg(st_length(st_transform(line.way, 4326) :: geography))) [ 1 ] as len
						from planet_osm_line line,
								 river_thames
						where st_intersects(line.way, river_thames.way)
							and bridge = 'yes'
							and lower(name) like '%bridge%'
							and lower(name) not like '%railway%'
						group by line.name) inputs) features;

---







