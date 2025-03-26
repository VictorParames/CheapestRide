import { Controller } from "@hotwired/stimulus"

const { Map } = await google.maps.importLibrary("maps");
const { AdvancedMarkerElement } = await google.maps.importLibrary("marker");
const { encoding } = await google.maps.importLibrary("geometry");
const { Polyline } = await google.maps.importLibrary("maps")
const { MapElement } = await google.maps.importLibrary("maps")
const { LatLng } = await google.maps.importLibrary("core")
const { LatLngBounds } = await google.maps.importLibrary("core")
const { InfoWindow } = await google.maps.importLibrary("maps")



// Connects to data-controller="map"
export default class extends Controller {

  static values = {
    origin: Array,
    destination: Array,
    key: String,
    drive: String,
    transit: String,
    pickup: String,
    dropoff: String,
  }
  connect() {

      console.log(this.originValue)
      /*   let map; */
        const origin = { lat: this.originValue[0] , lng: this.originValue[1] };
        const destination = { lat: this.destinationValue[0] , lng: this.destinationValue[1] };
        const drivePolyline = this.driveValue;
        const transitPolyline = this.transitValue;
        const originTag = document.createElement("div");
        const destinationTag = document.createElement("div");

        originTag.className = "price-tag octagonal btn btn-primary";
        originTag.textContent = this.pickupValue;
        destinationTag.className = "price-tag octagonal btn btn-primary";
        destinationTag.textContent = this.dropoffValue;

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
          content: originTag,
        });

        const marker2 = new AdvancedMarkerElement({
          map: map,
          position: destination,
          content: destinationTag,
        });
        const bounds = new LatLngBounds();
        // console.log(origin)
        // console.log(destination)
        bounds.extend(origin);
        bounds.extend(destination);
        map.fitBounds(bounds, {top:100, bottom:350});

        const drive_route = new Polyline({
        path: encoding.decodePath(drivePolyline),
        geodesic: true,
        strokeColor: "#9600ED",
        strokeOpacity: 1.0,
        strokeWeight: 3
        });
        drive_route.setMap(map);

        const transit_route = new Polyline({
          path: encoding.decodePath(transitPolyline),
          geodesic: true,
          strokeColor: "#FF0000",
          strokeOpacity: 1.0,
          strokeWeight: 3
        });
        transit_route.setMap(map);
  };

};
