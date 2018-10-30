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


@app.route('/radius', methods=['GET'])
def radius():
	lat = request.args.get('lat')
	lng = request.args.get('lng')
	radius = request.args.get('radius')

	logger.debug("lat: " + str(lat))

	cur = connect_to_db()

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
	return json.dumps(rows[0][0])


@app.route('/heatmap_italy', methods=['GET'])
def heatmap_italy():
	cur = connect_to_db()

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


@app.route('/', methods=['GET', 'POST'])
def get_title_page():
	logger.debug("Path: ", os.path.dirname(__file__))
	return app.send_static_file('index.html')


def connect_to_db():
	try:
		conn = psycopg2.connect(dbname='gis', host='localhost', port=5432, user='pmarusin', password='')

	except:
		logging.error("I am unable to connect to the database")

	cur = conn.cursor(cursor_factory=psycopg2.extras.DictCursor)
	logger.info("Connection do DB successful.")

	return cur


if __name__ == "__main__":
	app.run()
