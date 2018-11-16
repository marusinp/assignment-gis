var map;

// default coords, somewhere near Michalska brana
var lat = 48.145374;
var lng = 17.106794;
var defaultZoom = 20;

var shownLayers = [];
var shownSources = [];
var shownMarkers = [];

var crimeColorMap = {
    'Bicycle theft': '#3bb2d0',
    'Anti-social behaviour': '#fbb03b',
    'Vehicle crime': '#223b53',
    'Violence and sexual offences': '#e55e5e',
    'Criminal damage and arson': '#407058',
    'Possession of weapons': '#b96d40',
    'Robbery': '#b43434',
    'Burglary': '#610083',
    'Drugs': '#563400',
    'Public order': '#8590a7',
    'Theft from the person': '##00cc00',
    'Shoplifting': '#b5ddbd',
    'Other theft': '#d4ca63'
};


$('#radius_form').submit(function () {
    console.log("TEST");
    return false;
});


function mapCleanUp(excludeFlag) {

    // if (excludeFlag === '') {
        for (let i = 0; i < shownMarkers.length; i++) {
            shownMarkers[i].remove();
        }

        shownMarkers = [];
    // }

    for (let i = 0; i < shownLayers.length; i++) {
        map.removeLayer(shownLayers[i]);
    }
    for (let i = 0; i < shownSources.length; i++) {
        map.removeSource(shownSources[i]);
    }

    shownLayers = [];
    shownSources = [];

}

function addCoordsAndZoomListeners(map) {
    map.on('mousemove', function (e) {
        // e.lngLat is the longitude, latitude geographical position of the event
        document.getElementById('lng').innerHTML = e.lngLat['lng'];
        document.getElementById('lat').innerHTML = e.lngLat['lat'];


        // e.point is the x, y coordinates of the mousemove event relative
        // to the top-left corner of the map
        document.getElementById('map_x').innerHTML = e.point['x'];
        document.getElementById('map_y').innerHTML = e.point['y'];
    });
    map.on('zoomend', function (e) {
        // console.log(map.getZoom());
        document.getElementById('zoomlevel').innerHTML = map.getZoom();
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
        style: 'mapbox://styles/mapbox/streets-v10', // stylesheet location
        center: [lng, lat], // starting position [lng, lat]
        zoom: 10// starting zoom
    });

    map.addControl(new mapboxgl.GeolocateControl({
        positionOptions: {
            enableHighAccuracy: true
        },
        trackUserLocation: true
    }));


    document.getElementById('zoomlevel').innerHTML = map.getZoom();

    addCoordsAndZoomListeners(map);
    // debugOnClick();


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

function pickLocHook(e) {
    lng = e.lngLat.lng;
    lat = e.lngLat.lat;

    console.log(lng);
    console.log(lat);
    map.getCanvas().style.cursor = 'pointer';

    var geojson = [
        {
            type: 'Feature',
            geometry: {
                type: 'Point',
                coordinates: [lng, lat]
            }
        }
    ];

    geojson.forEach(function (marker) {

        // create a HTML element for each feature
        var el = document.createElement('div');
        el.className = 'marker-loc';

        // make a marker for each feature and add to the map
        marker = new mapboxgl.Marker(el)
            .setLngLat(marker.geometry.coordinates)
            .addTo(map);
        shownMarkers.push(marker);

    });

    //event handler deletes itself
    map.off('click', pickLocHook);
}


function radiusPickLocJS() {
    mapCleanUp();

    map.getCanvas().style.cursor = 'crosshair';
    map.on('click', pickLocHook);

}

function radiusJS() {

    mapCleanUp("marker-loc");

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

        map.flyTo({
            center: [lng, lat],
            zoom: 15
        });


        var geojson = JSON.parse(data);
        console.log(JSON.stringify(geojson));

        geojson.features.forEach(function (marker) {

            // create a HTML element for each feature
            var el = document.createElement('div');
            el.className = 'marker';

            // make a marker for each feature and add to the map
            marker = new mapboxgl.Marker(el)
                .setLngLat(marker.geometry.coordinates)
                .setPopup(new mapboxgl.Popup({offset: 75}) // add popups
                    .setHTML(fillPopup(marker.properties)))
                .addTo(map);
            shownMarkers.push(marker);
        });


        // map.addSource("polygon", createGeoJSONCircle([lng, lat], 1));
        //
        // map.addLayer({
        //     "id": "polygon",
        //     "type": "fill",
        //     "source": "polygon",
        //     "layout": {},
        //     "paint": {
        //         "fill-color": "blue",
        //         "fill-opacity": 0.6
        //     }
        // });

    });
}

function heatmapItalyJS() {

    mapCleanUp();

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
        shownSources.push('earthquakes');

        map.addSource('earthquakes', {
            type: 'geojson',
            data: geojson,
        });


        shownLayers.push('earthquakes');

        map.addLayer({
            id: 'earthquakes',
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

        shownLayers.push('earthquakes-point');

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


function heatmapLondonJS() {

    mapCleanUp();
    var borough = $("#boroughList").val();
    var requestData = {
        "crime_type": $("#crimeTypeList").val(),
        "borough": borough
    };
    var coords, zoom;
    if (borough === 'London Borough of Lambeth') {
        coords = {"lng": -0.1200575547209155, "lat": 51.456230797409944};
        zoom = 10.8;
    }
    else if (borough === 'City of Westminster') {
        coords = {"lng": -0.1333328, "lat": 51.499998};
        zoom = 10.8;
    } else if (borough === 'London Borough of Camden') {
        coords = {"lng": -0.166666, "lat": 51.5333312};
        zoom = 10.8;
    }
    console.log("DATA  REQ " + JSON.stringify(requestData));
    $.ajax({
        url: "/heatmap_london",
        data: requestData,
        type: "GET"
    }).done(function (data) {
        console.log(data);


        console.log('done');
        map.flyTo({
            center: coords,
            zoom: zoom
        });

        var geojson = JSON.parse(data);

        console.log(JSON.stringify(geojson));
        shownSources.push('criminality');
        //
        map.addSource('criminality', {
            type: 'geojson',
            data: geojson,
        });


        shownLayers.push('circle-criminality');

        map.addLayer({
            'id': 'circle-criminality',
            'type': 'circle',
            'source': 'criminality',
            'paint': {
                // make circles larger as the user zooms from z12 to z22
                'circle-radius': {
                    property: 'crime_type_count',
                    type: 'exponential',

                    'stops': [
                        [1, 6],
                        [80, 16]
                    ]
                },
                // color circles by crime type, using a match expression
                // https://www.mapbox.com/mapbox-gl-js/style-spec/#expressions-match
                'circle-color': [
                    'match',
                    ['get', 'crime_type'],
                    'Bicycle theft', '#3bb2d0',
                    'Anti-social behaviour', '#fbb03b',
                    'Vehicle crime', '#223b53',
                    'Violence and sexual offences', '#e55e5e',
                    'Criminal damage and arson', '#407058',
                    'Possession of weapons', '#b96d40',
                    'Robbery', '#b43434',
                    'Burglary', '#610083',
                    'Drugs', '#563400',
                    'Public order', '#f38020',
                    'Theft from the person', '#00cc00',
                    'Shoplifting', '#b5ddbd',
                    'Other theft', '#d4ca63',
                    'all', '#86898c',
                    /* other */ '#ccc'
                ],
                'circle-stroke-color': 'black',
                'circle-stroke-width': 1
            }
        });

        map.on('click', 'circle-criminality', function (e) {
            new mapboxgl.Popup()
                .setLngLat(e.features[0].geometry.coordinates)
                .setHTML('<b>' + e.features[0].properties.crime_type_count + '</b>' + ' criminal events of selected type took place here!')
                .addTo(map);
        });
    });


}


function routingJS() {

    mapCleanUp();


    var requestData = {
        "src": $("#srcList").val(),
        "stop": $("#stopList").val(),
        "dst": $("#dstList").val(),
    };



    console.log("DATA  REQ " + JSON.stringify(requestData));
    $.ajax({
        url: "/routing",
        data: requestData,
        type: "GET"
    }).done(function (data) {

        console.log("data " + data);

        data = JSON.parse(data);

        var points = data['points'].replace(/\\"/g, '"');
        var route = data['route'].replace(/\\"/g, '"');


        // console.log(typeof data);
        console.log("body       " + points);
        console.log("cesta       " + route);


        var route_geojson = JSON.parse(route.slice(1, -1));
        var points_geojson = JSON.parse(points);
        // console.log(geojson.coordinates[0]);

        map.flyTo({
            center: points_geojson.features[0].geometry.coordinates,
            zoom: 10
        });


        points_geojson.features.forEach(function (marker) {

            // create a HTML element for each feature
            var el = document.createElement('div');
            el.className = 'marker';

            // make a marker for each feature and add to the map
            marker = new mapboxgl.Marker(el)
                .setLngLat(marker.geometry.coordinates)
                .setPopup(new mapboxgl.Popup({offset: 75}) // add popups
                    .setHTML('<h3>' + marker.properties.name + '</h3>'))
                .addTo(map);
            shownMarkers.push(marker);
        });

        // console.log('data JSON: ' + JSON.stringify(geojson));

        shownLayers.push('routing_line');
        shownSources.push('routing_line');

        map.addLayer({
            id: "routing_line",
            type: "line",
            source: {
                type: "geojson",
                data: {
                    "type": "FeatureCollection",
                    "features": [
                        {
                            "type": "Feature",
                            "properties": {},
                            "geometry": route_geojson
                        }
                    ]
                }
            },
            'paint': {
                'line-width': 4,
                // Use a get expression (https://www.mapbox.com/mapbox-gl-js/style-spec/#expressions-get)
                // to set the line-color to a feature property value.
                'line-color': 'red'
            }
        });
    });

}

function thamesBridgesJS() {

    mapCleanUp();

    var requestData = {};
    console.log("DATA  REQ " + JSON.stringify(requestData));
    $.ajax({
        url: '/thames_bridges',
        data: requestData,
        type: "GET"
    }).done(function (data) {
        // data = data.replace(/\\/g, '');
        // console.log("data " + data);


        // console.log(typeof data);
        // var geojson = JSON.parse(data.slice(1, -1));
        var geojson = JSON.parse(data);
        console.log(JSON.stringify(geojson));

        map.flyTo({
            center: [-0.21744179493470028, 51.47596429713249],
            zoom: 10.826985437949697
        });

        // console.log('data JSON: ' + JSON.stringify(geojson));
        shownLayers.push('bridges');
        shownSources.push('bridges');

        map.addSource('bridges', {
            type: 'geojson',
            data: geojson,
        });


        map.addLayer({
            "id": "bridges",
            "type": "line",
            "source": "bridges",
            'paint': {
                'line-width': 4,
                // Use a get expression (https://www.mapbox.com/mapbox-gl-js/style-spec/#expressions-get)
                // to set the line-color to a feature property value.
                'line-color': 'red'
            }
        });

        geojson.features.forEach(function (marker) {

            // create a HTML element for each feature
            var el = document.createElement('div');
            el.className = 'marker-bridge';
            // marker.anchor = 'up';
            let marker_pos_offset = 0.001;
            // make a marker for each feature and add to the map
            marker = new mapboxgl.Marker(el)
                .setLngLat([marker.geometry.coordinates[0][0], marker.geometry.coordinates[0][1]])
                .setPopup(new mapboxgl.Popup({offset: 75}) // add popups
                    .setHTML('<b> Bridge name: </b>' + marker.properties.name
                        + '<br> <b> Bridge length: </b>' + Math.round(parseFloat(marker.properties.len) * 100) / 100 + ' m'))
                .addTo(map);
            shownMarkers.push(marker);
        });


    });

}