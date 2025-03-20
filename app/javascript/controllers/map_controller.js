import { Controller } from "@hotwired/stimulus"

const { Map } = await google.maps.importLibrary("maps");
const { AdvancedMarkerElement } = await google.maps.importLibrary("marker");
const { encoding } = await google.maps.importLibrary("geometry");
const { Polyline } = await google.maps.importLibrary("maps")

const getRouteDrive = (pickupLat, pickupLng, dropoffLat, dropoffLng, key) => {
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
const getRouteTraffic = (pickupLat, pickupLng, dropoffLat, dropoffLng, key) => {
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
    travelMode: 'TRANSIT',
    computeAlternativeRoutes: true,
  };

  return fetch(url, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'X-Goog-Api-Key': `${key}`, // Replace with your actual Google Maps API key
      'X-Goog-FieldMask': 'routes.legs.steps.transitDetails'
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

    console.log(this.originValue)
    /*   let map; */
      const origin = { lat: this.originValue[0] , lng: this.originValue[1] };
      const destination = { lat: this.destinationValue[0] , lng: this.destinationValue[1] };

      const map = new Map(this.element, {
        zoom: 13,
        center: origin,
        disableDefaultUI: true,
        gestureHandling: "greedy",
        mapId: "8735f642fde9fc3c",
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


    getRouteDrive(this.originValue[0], this.originValue[1], this.destinationValue[0], this.destinationValue[1], this.keyValue)
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
    getRouteTraffic(this.originValue[0], this.originValue[1], this.destinationValue[0], this.destinationValue[1], this.keyValue)
    .then(routeData => {
      console.log(routeData.routes);

      const route = new Polyline({
        path: routeData.routes,
        geodesic: true,
        strokeColor: "#FF0000",
        strokeOpacity: 1.0,
        strokeWeight: 2
      });
      route.setMap(map);
    });
  }
}
