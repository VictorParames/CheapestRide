import { Controller } from "@hotwired/stimulus"

const { Map } = await google.maps.importLibrary("maps");


// Connects to data-controller="map"
export default class extends Controller {


  connect() {

    console.log(this.originValue)
    /*   let map; */
      const origin = { lat: -23.5501141 , lng: -46.6527041 };

      const map = new Map(this.element, {
        zoom: 12,
        center: origin,
        disableDefaultUI: true,
        gestureHandling: "greedy",
        mapId: "8735f642fde9fc3c",
      });

  };

};
