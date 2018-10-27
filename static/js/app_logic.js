var map, styleLayer;

// default coords, somewhere near Michalska brana
var lat = 48.145374;
var lng = 17.106794;
var defaultZoom = 20;


// function setGeoPosition() {
//     if (navigator.geolocation) {
//         // check if geolocation is supported/enabled on current browser
//         navigator.geolocation.getCurrentPosition(
//             function success(position) {
//                 // Location successful
//                 lat = position.coords.latitude;
//                 lng = position.coords.longitude;
//
//                 map.panTo([lat, lng]);
//                 // mode(defaultMode, lat, lng);
//             }, function error(position) {
//                 // for when getting location results in an error (user refuses to share GPS location)
//                 console.error('An error has occured while retrieving location');
//
//                 map.panTo([lat, lng]);
//                 // mode(defaultMode, lat, lng);
//             });
//     }
//     else {
//         // geolocation is not supported
//         console.log('geolocation is not enabled on this browser');
//
//         map.panTo([lat, lng]);
//         // mode(defaultMode, lat, lng);
//
//     }
// }


function initMap(lat, lng, zoom) {

    mapboxgl.accessToken = 'pk.eyJ1IjoibWFydXNpbnAiLCJhIjoiY2puMXh0emFsMjN6bzN2cGx1MHg1aGlxYyJ9.4_us1_f4fGyKvFPnyYp1gw';
    map = new mapboxgl.Map({
        container: 'map', // container id
        style: 'mapbox://styles/mapbox/streets-v9', // stylesheet location
        center: [lng, lat], // starting position [lng, lat]
        zoom: 5// starting zoom
    });

    map.addControl(new mapboxgl.GeolocateControl({
        positionOptions: {
            enableHighAccuracy: true
        },
        trackUserLocation: true
    }));

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
        "radius": 1000,
    };
    console.log("DATA  REQ " + JSON.stringify(requestData));
    $.ajax({
        url: "/radius",
        data: requestData,
        type: "POST"
    }).done(function (data) {

        // var geojson = JSON.parse(data);
        // console.log(JSON.stringify(geojson));
        //
        // geojson.features.forEach(function (marker) {
        //
        //     // create a HTML element for each feature
        //     var el = document.createElement('div');
        //     el.className = 'marker';
        //
        //     // make a marker for each feature and add to the map
        //     new mapboxgl.Marker(el)
        //         .setLngLat(marker.geometry.coordinates)
        //         .setPopup(new mapboxgl.Popup({offset: 75}) // add popups
        //             .setHTML(fillPopup(marker.properties)))
        //         .addTo(map);
        // });
        //
        // map.addSource("polygon", createGeoJSONCircle([lng, lat], 0.5));
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


        var geojson = JSON.parse(data);
        console.log(JSON.stringify(geojson));

 map.addSource('trees', {
        type: 'geojson',
        data: geojson,
    });


    map.addLayer({
        id: 'trees-heat',
        type: 'heatmap',
        source: 'trees',
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
                    [17, 3]
                ]
            },
            // assign color values be applied to points depending on their density
            'heatmap-color': [
                'interpolate',
                ['linear'],
                ['heatmap-density'],
                0, 'rgba(236,222,239,0)',
                0.2, 'rgb(208,209,230)',
                0.4, 'rgb(166,189,219)',
                0.6, 'rgb(103,169,207)',
                0.8, 'rgb(28,144,153)'
            ],
            // increase radius as zoom increases
            'heatmap-radius': {
                stops: [
                    [11, 30],
                    [15, 45]
                ]
            },
            // decrease opacity to transition into the circle layer
            'heatmap-opacity': {
                default: 1,
                stops: [
                    [14, 1],
                    [19, 0]
                ]
            },
        }
    }, 'waterway-label');

    map.on('click', 'trees-point', function (e) {
        new mapboxgl.Popup()
            .setLngLat(e.features[0].geometry.coordinates)
            .setHTML('<b>DBH:</b> ' + e.features[0].properties.magnitude)
            .addTo(map);
    });
        // var jsondata = JSON.parse(data);
        // console.log(jsondata[0]);
        // L.geoJSON(jsondata[0][0].features).addTo(map);
        // console.log(JSON.stringify(jsondata.features));
    });




}




// $("#btnBike").click(function (event) {
//     event.preventDefault();
//     gjsonLayer.loadURL('/map/radius?distance=' + $("#custom-handle").html() + '&lat=' + lat + '&lng=' + lng);
// });
