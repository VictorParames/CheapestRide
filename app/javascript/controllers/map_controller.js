import { Controller } from "@hotwired/stimulus"

const { Map } = await google.maps.importLibrary("maps");
const { AdvancedMarkerElement } = await google.maps.importLibrary("marker");
const { encoding } = await google.maps.importLibrary("geometry");
const { Polyline } = await google.maps.importLibrary("maps")

const getRouteDirections = (pickupLat, pickupLng, dropoffLat, dropoffLng, key) => {
  const url = 'https://routes.googleapis.com/directions/v2:computeRoutes'; // Google Maps Routes API endpoint

  const body = {
    origin: {
      location:{
        latLng: {
          latitude: pickupLat,
          longitude: pickupLng,
        }
      }
    },
    destination: {
      location: {
        latLng: {
          latitude: dropoffLat,
          longitude: dropoffLng,
        }
      }
    },
    travelMode: 'DRIVE',
    routingPreference: "TRAFFIC_AWARE",
    computeAlternativeRoutes: false,
    routeModifiers: {
      avoidTolls: false,
      avoidHighways: false,
      avoidFerries: false
    },
    languageCode: "en-US",
    units: "METRIC"
  };

  return fetch(url, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'X-Goog-Api-Key': `${key}`, // Replace with your actual Google Maps API key
      'X-Goog-FieldMask': 'routes.duration,routes.distanceMeters,routes.polyline.encodedPolyline'
    },
    body: JSON.stringify(body),
  })
  .then(response => {
    if (!response.ok) {
      throw new Error('Failed to fetch route data');
    }
    return response.json(); // Parse JSON if response is OK
  })
  .catch(error => {
    console.error('Error fetching route directions:', error);
  });
};

// Connects to data-controller="map"
export default class extends Controller {

  static values = {
    origin: Array,
    destination: Array,
    key: String
  }
  connect() {

/*
    const polyPromise = encodedpath
    const path = polyPromise.then((encodedPolyline) => {
      displayRouteOnMap(encoding.decodePath(encodedPolyline))
      console.log(encodedPolyline)
      console.log("-------")
      return encodedPolyline
    })
    console.log(encodedpath)
    const path = new encoding.decodePath(polypath)
    console.log(path)
    console.log(path) */




    console.log(this.originValue)
    /*   let map; */
      const origin = { lat: this.originValue[0] , lng: this.originValue[1] };
      const destination = { lat: this.destinationValue[0] , lng: this.destinationValue[1] };

      const map = new Map(this.element, {
        zoom: 13,
        center: origin,
        mapId: "DEMO_MAP_ID",
      });


      const marker = new AdvancedMarkerElement({
        map: map,
        position: origin,
        title: "Demo-marker",
      });

      const marker2 = new AdvancedMarkerElement({
        map: map,
        position: destination,
        title: "Demo-marker2",
      });


    getRouteDirections(this.originValue[0], this.originValue[1], this.destinationValue[0], this.destinationValue[1], this.keyValue)
    .then(routeData => {
      console.log(encoding.decodePath(routeData.routes[0].polyline.encodedPolyline));

      const route = new Polyline({
        path: encoding.decodePath(routeData.routes[0].polyline.encodedPolyline),
        geodesic: true,
        strokeColor: "#FF0000",
        strokeOpacity: 1.0,
        strokeWeight: 2
      });
      route.setMap(map);
    });

/*       const route = new Polyline({
        map: map,
        path: `${path}`
      }) */
  }
}
