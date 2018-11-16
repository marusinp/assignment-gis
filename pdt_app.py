from flask import Flask
from flask import request, redirect, Response
import os
import json
import psycopg2
import psycopg2.extras
import logging

app = Flask(__name__)
app.config['SECRET_KEY'] = 'dev'
app.config['DEBUG'] = True

logger = logging.getLogger()
logger.setLevel(logging.DEBUG)
fh = logging.FileHandler('debug.log')
sh = logging.StreamHandler()
fh.setLevel(logging.DEBUG)
sh.setLevel(logging.DEBUG)
formatter = logging.Formatter('%(levelname)s: %(message)s')
fh.setFormatter(formatter)
sh.setFormatter(formatter)
logger.addHandler(sh)
logger.addHandler(fh)


@app.route('/<path:path>')
def static_file(path):
	return app.send_static_file(path)


@app.route('/routing', methods=['GET'])
def routing():
	# logger.debug(request)
	# logger.debug(request.data)
	src = request.args.get('src')
	stop = request.args.get('stop')
	dst = request.args.get('dst')

	logger.debug("src: " + str(src))

	cur = connect_to_db('london-db')

	# 	old_query = """
	# 	with src as (select st_transform(point.way, 4326) as way,
	# 																												vertices.id                   as src_id,
	# 																												point.osm_id,
	# 																												point.amenity,
	# 																												point.name
	# 																								 from planet_osm_point as point
	# 																												JOIN ways_vertices_pgr as vertices
	# 																													ON (point.osm_id = vertices.osm_id)
	# 																								 where lower(name) = 'lekáreň sv. michala'
	# 																								 limit 1),
	# 																				 stop as (select st_transform(point.way, 4326) as way,
	# 																												 vertices.id                   as stop_id,
	# 																												 point.osm_id,
	# 																												 point.amenity,
	# 																												 point.name
	# 																									from planet_osm_point as point
	# 																												 JOIN ways_vertices_pgr as vertices
	# 																													 ON (point.osm_id = vertices.osm_id)
	# 																									where lower(name) = 'santal'
	# 																									limit 1),
	# 																				 dst as (select st_transform(point.way, 4326) as way,
	# 																												vertices.id                   as dst_id,
	# 																												point.osm_id,
	# 																												point.amenity,
	# 																												point.name
	# 																								 from planet_osm_point as point
	# 																												JOIN ways_vertices_pgr as vertices
	# 																													ON (point.osm_id = vertices.osm_id)
	# 																								 where lower(name) = 'slovenská sporiteľňa'
	# 																								 limit 1)
	# 																		select ST_AsGeoJSON(st_union((merged_route.the_geom))),
	# 																					 st_asgeojson(st_union((src.way))),
	# 																					 st_asgeojson(st_union((stop.way))),
	# 																					 st_asgeojson(st_union(dst.way))
	# 																		from (SELECT ways.the_geom
	# 																					from pgr_dijkstra('SELECT gid as id, source, target,
	# 							 length as cost FROM ways',
	# 																														(select src_id from src),
	# 																														(select stop_id from stop),
	# 																														directed := false
	# 																									 ) src_stop_dij
	# 																								 JOIN ways ON (src_stop_dij.edge = ways.gid)
	# 																					union
	# 																					SELECT ways.the_geom
	# 																					from pgr_dijkstra('
	#                 SELECT gid as id, source, target,
	#                         length as cost FROM ways',
	# 																														(select stop_id from stop),
	# 																														(select dst_id from dst),
	# 																														directed := false
	# 																									 ) stop_dst_dij
	# 																								 JOIN ways ON (stop_dst_dij.edge = ways.gid)) merged_route,
	# 																				 src,
	# 																				 stop,
	# 																				 dst
	# """

	cur.execute("""SELECT jsonb_build_object(
				 'type', 'FeatureCollection',
				 'features', jsonb_agg(feature)
					 )
FROM (SELECT jsonb_build_object(
							 'type', 'Feature',
							 'geometry', ST_AsGeoJSON(ST_Transform(way, 4326)) :: jsonb,
							 'properties', jsonb_strip_nulls(jsonb_build_object(
																								 'name', name,
																								 'vertex_id',vertex_id
																									 ))
								 ) AS feature
			FROM (select distinct ON(point.name) point.name,
									 st_transform(point.way, 4326) as way,
									 vertices.id                   as vertex_id,
									 point.osm_id
						from planet_osm_point as point
									 JOIN ways_vertices_pgr as vertices ON (point.osm_id = vertices.osm_id)
						where (name) = '{src}'
							 or (name) = '{stop}'
							 or (name) = '{dst}'
						) inputs) features;
						""".format(src=src, stop=stop, dst=dst))

	rows = cur.fetchall()
	response = {'points': json.dumps(rows[0][0], ensure_ascii=False)}

	names = [e["properties"]["name"] for e in rows[0][0]["features"]]

	src_id, stop_id, dst_id = rows[0][0]["features"][names.index(src)]["properties"]["vertex_id"], \
							  rows[0][0]["features"][names.index(stop)]["properties"]["vertex_id"], \
							  rows[0][0]["features"][names.index(dst)]["properties"]["vertex_id"]

	cur.execute("""
		select ST_AsGeoJSON(st_union((merged_route.the_geom)))
																		from (SELECT ways.the_geom
																					from pgr_dijkstra('SELECT gid as id, source, target,
							 length as cost FROM ways',
																														{src_id},
																														{stop_id},
																														directed := false
																									 ) src_stop_dij
																								 JOIN ways ON (src_stop_dij.edge = ways.gid)
																					union
																					SELECT ways.the_geom
																					from pgr_dijkstra('
                SELECT gid as id, source, target,
                        length as cost FROM ways',
																														{stop_id},
																														{dst_id},
																														directed := false
																									 ) stop_dst_dij
																								 JOIN ways ON (stop_dst_dij.edge = ways.gid)) merged_route;
							""".format(src_id=src_id, stop_id=stop_id, dst_id=dst_id))

	rows = cur.fetchall()
	response['route'] = json.dumps(rows[0][0], ensure_ascii=False)

	return json.dumps(response)


@app.route('/radius', methods=['GET'])
def radius():
	logger.debug(request)
	logger.debug(request.data)
	lat = request.args.get('lat')
	lng = request.args.get('lng')
	radius = request.args.get('radius')

	logger.debug("lat: " + str(lat))

	cur = connect_to_db('gis')

	cur.execute("""CREATE INDEX gist_geog_point ON planet_osm_point USING GIST (geography(st_transform(way,4326)));""")

	cur.execute("""
	with poi as (
	SELECT name, osm_id, way, "addr:street", "addr:housenumber",operator,website,outdoor_seating, internet_access,smoking,opening_hours FROM planet_osm_point
    where amenity = 'cafe'
    and ST_DWithin(st_transform(way,4326)::geography, ST_SetSRID(ST_MakePoint({lng}, {lat}), 4326)::geography, {radius})
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
""".format(lat=lat, lng=lng, radius=radius))

	rows = cur.fetchall()

	cur.execute("""drop index gist_geog_point;""")

	return json.dumps(rows[0][0])


@app.route('/heatmap_italy', methods=['GET'])
def heatmap_italy():
	cur = connect_to_db('gis')

	cur.execute("""
		SELECT jsonb_build_object(
  'type',     'FeatureCollection',
  'features', jsonb_agg(feature)
)
FROM (
  SELECT jsonb_build_object(
    'type',       'Feature',
    'geometry',   ST_AsGeoJSON(ST_Transform(geom,4326))::jsonb,
    'properties', jsonb_strip_nulls(jsonb_build_object(
   		'magnitude', magnitude

  ))
  ) AS feature
  FROM (
    SELECT magnitude,geom FROM italy
  ) inputs
) features
	""")

	rows = cur.fetchall()
	return json.dumps(rows[0][0])


@app.route('/heatmap_london', methods=['GET'])
def heatmap_london():
	cur = connect_to_db('london-db')

	borough = request.args.get('borough')
	crime_type = request.args.get('crime_type')
	row_limit = request.args.get('row_limit')

	cur.execute("""CREATE INDEX if not exists gist_geom_crime_records
	ON crime_records
	USING GIST (st_transform(geom, 4326));
	""")

	borough_crime_type_query = """with borough as (select st_transform(way, 4326) as geom
								 from planet_osm_polygon
								 where name = '{borough}')
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
			where crime_type = '{crime_type}'
						group by crime_records.geom, crime_type
					 ) inputs) features;
	""".format(crime_type=crime_type, borough=borough)

	borough_query = """with borough as (select st_transform(way, 4326) as geom
								 from planet_osm_polygon
								 where name = '{borough}')
SELECT jsonb_build_object(
				 'type', 'FeatureCollection',
				 'features', jsonb_agg(feature)
					 )
FROM (SELECT jsonb_build_object(
							 'type', 'Feature',
							 'geometry', ST_AsGeoJSON(ST_Transform(geom, 4326)) :: jsonb,
							 'properties', jsonb_strip_nulls(jsonb_build_object(
																								 'crime-type','all',
																								 'crime_type_count', crime_type_count
																									 ))
								 ) AS feature
			FROM (SELECT crime_records.geom, count(crime_type) as crime_type_count
						FROM crime_records
									 join borough on st_contains(borough.geom, st_transform(crime_records.geom, 4326))
		  
						group by crime_records.geom
					 ) inputs) features;
	""".format(borough=borough)

	color_query = """with borough as (select st_transform(way, 4326) as geom
								 from planet_osm_polygon
								 where name = '{borough}')
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
	""".format(borough=borough)

	if crime_type == 'color' and borough != 'all':
		cur.execute(color_query)
	elif crime_type != 'all' and borough != 'all':
		cur.execute(borough_crime_type_query)
	elif crime_type == 'all' and borough != 'all':
		cur.execute(borough_query)

	rows = cur.fetchall()
	return json.dumps(rows[0][0])


@app.route('/thames_bridges', methods=['GET'])
def thames_bridges():
	cur = connect_to_db('london-db')

	cur.execute("""
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
	""")

	rows = cur.fetchall()
	return json.dumps(rows[0][0])


@app.route('/', methods=['GET', 'POST'])
def get_title_page():
	logger.debug("Path: ", os.path.dirname(__file__))
	return app.send_static_file('index.html')


def connect_to_db(db_name):
	try:
		conn = psycopg2.connect(dbname=db_name, host='localhost', port=5432, user='pmarusin', password='')

	except:
		logging.error("I am unable to connect to the database")

	cur = conn.cursor(cursor_factory=psycopg2.extras.DictCursor)
	logger.info("Connection do DB successful.")

	return cur


if __name__ == "__main__":
	app.run()
