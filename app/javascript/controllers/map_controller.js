import { Controller } from "@hotwired/stimulus"

const { Map } = await google.maps.importLibrary("maps");
const { AdvancedMarkerElement } = await google.maps.importLibrary("marker");

// Connects to data-controller="map"
export default class extends Controller {
  static values = {
    origin: Array,
    destination: Array
  }
  connect() {
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
  }
}
