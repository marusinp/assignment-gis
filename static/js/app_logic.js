var map, styleLayer;

// default coords, somewhere near Michalska brana
var lat = 48.145374;
var lng = 17.106794;
var defaultZoom = 20;


$('#radius_form').submit(function () {
    console.log("TEST");
    return false;
});


function showCoordsAndZoom(map) {
    map.on('mousemove', function (e) {
        // e.lngLat is the longitude, latitude geographical position of the event
        document.getElementById('lng').innerHTML = "Lng: " + e.lngLat['lng'];
        document.getElementById('lat').innerHTML = "Lat: " + e.lngLat['lat'];


        // e.point is the x, y coordinates of the mousemove event relative
        // to the top-left corner of the map
        document.getElementById('map_x').innerHTML = "Map X: " + e.point['x'];
        document.getElementById('map_y').innerHTML = "Map Y: " + e.point['y'];
    });
    map.on('zoomend', function (e) {
        // console.log(map.getZoom());
        document.getElementById('zoomlevel').innerHTML = "Zoom level: " + map.getZoom();
        // console.log(map.getZoom());
    });
}

function debugOnClick() {
    map.on('click', function (e) {
        map.flyTo({center: e.lngLat});
        console.log(JSON.stringify(e.lngLat));
        console.log(map.getZoom());
    });
}

function initMap(lat, lng, zoom) {

    mapboxgl.accessToken = 'pk.eyJ1IjoibWFydXNpbnAiLCJhIjoiY2puMXh0emFsMjN6bzN2cGx1MHg1aGlxYyJ9.4_us1_f4fGyKvFPnyYp1gw';
    map = new mapboxgl.Map({
        container: 'map', // container id
        style: 'mapbox://styles/mapbox/streets-v9', // stylesheet location
        center: [lng, lat], // starting position [lng, lat]
        zoom: 10// starting zoom
    });

    map.addControl(new mapboxgl.GeolocateControl({
        positionOptions: {
            enableHighAccuracy: true
        },
        trackUserLocation: true
    }));

    showCoordsAndZoom(map);
    debugOnClick();


}

initMap(lat, lng, defaultZoom);


function fillPopup(properties) {
    var descr = '';

    descr += '<h3>' + properties.name + '</h3>';
    descr += "<table class=\"popup-table\">";
    for (var property in properties) {
        var key = property;
        var value = properties[property];
        descr += '<tr>';
        descr += '<th style="text-align:left;font-weight:bold">' + key + '</th>';
        descr += '<th style=\" text-align:left\">' + value + '</th>';
        descr += '</tr>'
    }
    descr += "</table>";
    // console.log(descr);

    return descr;


}

var createGeoJSONCircle = function (center, radiusInKm, points) {
    if (!points) points = 64;

    var coords = {
        latitude: center[1],
        longitude: center[0]
    };

    var km = radiusInKm;

    var ret = [];
    var distanceX = km / (111.320 * Math.cos(coords.latitude * Math.PI / 180));
    var distanceY = km / 110.574;

    var theta, x, y;
    for (var i = 0; i < points; i++) {
        theta = (i / points) * (2 * Math.PI);
        x = distanceX * Math.cos(theta);
        y = distanceY * Math.sin(theta);

        ret.push([coords.longitude + x, coords.latitude + y]);
    }
    ret.push(ret[0]);

    return {
        "type": "geojson",
        "data": {
            "type": "FeatureCollection",
            "features": [{
                "type": "Feature",
                "geometry": {
                    "type": "Polygon",
                    "coordinates": [ret]
                }
            }]
        }
    };
};


function radiusJS() {
    var requestData = {
        "lat": lat,
        "lng": lng,
        "radius": $("#radiusTextField").val()
    };
    console.log("DATA  REQ " + JSON.stringify(requestData));
    $.ajax({
        url: "/radius",
        data: requestData,
        datatype: 'json',
        type: "GET"
    }).done(function (data) {


        var geojson = JSON.parse(data);
        console.log(JSON.stringify(geojson));

        geojson.features.forEach(function (marker) {

            // create a HTML element for each feature
            var el = document.createElement('div');
            el.className = 'marker';

            // make a marker for each feature and add to the map
            new mapboxgl.Marker(el)
                .setLngLat(marker.geometry.coordinates)
                .setPopup(new mapboxgl.Popup({offset: 75}) // add popups
                    .setHTML(fillPopup(marker.properties)))
                .addTo(map);
        });

        map.addSource("polygon", createGeoJSONCircle([lng, lat], 1));

        map.addLayer({
            "id": "polygon",
            "type": "fill",
            "source": "polygon",
            "layout": {},
            "paint": {
                "fill-color": "blue",
                "fill-opacity": 0.6
            }
        });

    });
}

function heatmapItalyJS() {
    var requestData = {
        // "lat": lat,
        // "lng": lng,
        // "radius": 1000,
    };

    map.flyTo({
        center: [14.301276935814514, 42.83708763735561],
        zoom: 6.737044040050586
    });

    // console.log("DATA  REQ " + JSON.stringify(requestData));
    $.ajax({
        url: "/heatmap_italy",
        data: requestData,
        type: "GET"
    }).done(function (data) {

        var geojson = JSON.parse(data);

        // console.log(JSON.stringify(geojson));

        map.addSource('earthquakes', {
            type: 'geojson',
            data: geojson,
        });


        map.addLayer({
            id: 'earthquakes-heat',
            type: 'heatmap',
            source: 'earthquakes',
            maxzoom: 24,
            paint: {
                // increase weight as diameter breast height increases
                'heatmap-weight': {
                    property: 'magnitude',
                    type: 'exponential',
                    stops: [
                        [0, 0],
                        [6.5, 1]
                    ]
                },
                // increase intensity as zoom level increases
                'heatmap-intensity': {
                    stops: [
                        [11, 1],
                        [15, 3]
                    ]
                },
                // assign color values be applied to points depending on their density
                'heatmap-color': [
                    'interpolate',
                    ['linear'],
                    ['heatmap-density'],
                    0, 'rgba(236,222,239,0)',
                    0.2, 'blue',
                    0.4, 'yellow',
                    0.6, 'orange',
                    0.8, 'red'
                ],
                // increase radius as zoom increases
                'heatmap-radius': {
                    stops: [
                        [11, 15],
                        [15, 20]
                    ]
                },
                // decrease opacity to transition into the circle layer
                'heatmap-opacity': {
                    default: 1,
                    stops: [
                        [14, 1],
                        [15, 0]
                    ]
                },
            }
        }, 'waterway-label');

        map.addLayer({
            id: 'earthquakes-point',
            type: 'circle',
            source: 'earthquakes',
            minzoom: 14,
            paint: {
                // increase the radius of the circle as the zoom level and dbh value increases
                'circle-radius': {
                    property: 'magnitude',
                    type: 'exponential',
                    stops: [
                        [{zoom: 15, value: 1}, 5],
                        [{zoom: 15, value: 62}, 10],
                        [{zoom: 22, value: 1}, 20],
                        [{zoom: 22, value: 62}, 50],
                    ]
                },
                'circle-color': {
                    property: 'magnitude',
                    type: 'exponential',
                    stops: [
                        [0, 'rgba(236,222,239,0)'],
                        [1, 'blue'],
                        [2, 'yellow'],
                        [3, 'orange'],
                        [4, 'red'],
                        [5, 'darkred']
                        // [6, 'rgb(1,108,89)']
                    ]
                },
                'circle-stroke-color': 'white',
                'circle-stroke-width': 1,
                'circle-opacity': {
                    stops: [
                        [14, 0],
                        [15, 1]
                    ]
                }
            }
        }, 'waterway-label');


        map.on('click', 'earthquakes-point', function (e) {
            new mapboxgl.Popup()
                .setLngLat(e.features[0].geometry.coordinates)
                .setHTML('<b>Magnitude:</b> ' + e.features[0].properties.magnitude)
                .addTo(map);
        });
    });

}

function routingJS() {
    var requestData = {
        "src": "lekáreň sv. michala",
        "stop": "santal",
        "dst": "slovenská sporiteľňa"
    };
    console.log("DATA  REQ " + JSON.stringify(requestData));
    $.ajax({
        url: "/routing",
        data: requestData,
        type: "GET"
    }).done(function (data) {
        data = data.replace(/\\/g, '');
        // console.log("data2 " + data);


        // console.log(typeof data);
        var geojson = JSON.parse(data.slice(1, -1));
        // console.log(geojson.coordinates[0]);

        map.flyTo({
            center: geojson.coordinates[0][0],
            zoom: 16
        });

        // console.log('data JSON: ' + JSON.stringify(geojson));

        map.addLayer({
            id: "routing_line",
            source: {
                type: "geojson",
                data: {
                    "type": "FeatureCollection",
                    "features": [
                        {
                            "type": "Feature",
                            "properties": {},
                            "geometry": geojson
                        }
                    ]
                }
            },
            type: "line"
        })
    });


}