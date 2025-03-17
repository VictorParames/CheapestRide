import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="search"
export default class extends Controller {
  static values = {
    token: String,
  }
  connect() {
    const showMapAndCoordinates = (userInput) => {

      const url = `https://maps.googleapis.com/maps/api/geocode/json?address="${userInput}"&key=${this.tokenValue}`;

      fetch(url)
        .then(response => response.json())
        .then((data) => {
          console.log(data);
          // TODO #4: Extract the coordinates from the parsed JSON response (longitude, latitude)
          const lat = data.results[0].geometry.location.lat;
          const lng = data.results[0].geometry.location.lng;

          console.log(lat);
          console.log(lng);

        });
    };
    const formInput = document.querySelector("#search .form-control");
    const formSubmit = document.querySelector("#search .btn");

    formSubmit.addEventListener("click", (event) => {
      event.preventDefault();
      const userInput = formInput.value;
      console.log(userInput);
      showMapAndCoordinates(userInput);
    }); // - refatorar o Codigo para Stimulus!!!!
  }
}
