// app/javascript/channels/ride_channel.js
import consumer from "./consumer";

document.addEventListener("DOMContentLoaded", () => {
  const rideChannelElement = document.getElementById("ride-channel");
  if (!rideChannelElement) {
    console.error("Elemento #ride-channel não encontrado!");
    return;
  }

  const rideId = rideChannelElement.dataset.rideId;
  if (!rideId) {
    console.error("ride_id não encontrado no elemento #ride-channel!");
    return;
  }

  // Função para atualizar a página com os dados recebidos
  const updatePage = (data) => {
    console.log("Dados recebidos:", data);

    // Atualizar a seção de distância e duração
    const distanceDuration = document.getElementById("distance-duration");
    if (data.distance && data.duration) {
      distanceDuration.innerHTML = `<p style="color: #333;">Distância total: ${data.distance} km, Duração total: ${data.duration} minutos</p>`;
    }

    // Atualizar a seção de possibilidades (preços)
    const optionsSection = document.getElementById("options-section");
    if (data.uber_price || data.ninetynine_price || data.indrive_price || data.metro_price) {
      let html = '<h2 class="options-title" style="color: #333;">Possibilidades</h2>';

      // Card Uber
      if (data.uber_price && data.uber_price > 0) {
        html += `
          <div class="option-card">
            <div class="option-details">
              <div class="option-icon-title">
                <i class="fa-solid fa-car option-icon"></i>
                <span class="option-title" style="color: yellow;">Uber</span>
              </div>
              <span class="option-price" style="color: yellow;">R$ ${data.uber_price.toFixed(2).replace('.', ',')}</span>
            </div>
          </div>
        `;
      } else {
        html += '<p>Preço do Uber não disponível no momento.</p>';
      }

      // Card 99
      if (data.ninetynine_price && data.ninetynine_price > 0) {
        html += `
          <div class="option-card">
            <div class="option-details">
              <div class="option-icon-title">
                <i class="fa-solid fa-car option-icon"></i>
                <span class="option-title" style="color: yellow;">99</span>
              </div>
              <span class="option-price" style="color: yellow;">R$ ${data.ninetynine_price.toFixed(2).replace('.', ',')}</span>
            </div>
          </div>
        `;
      } else {
        html += '<p>Preço do 99 não disponível no momento.</p>';
      }

      // Card InDrive
      if (data.indrive_price && data.indrive_price > 0) {
        html += `
          <div class="option-card">
            <div class="option-details">
              <div class="option-icon-title">
                <i class="fa-solid fa-car option-icon"></i>
                <span class="option-title" style="color: yellow;">InDrive</span>
              </div>
              <span class="option-price" style="color: yellow;">R$ ${data.indrive_price.toFixed(2).replace('.', ',')}</span>
            </div>
          </div>
        `;
      } else {
        html += '<p>Preço do InDrive não disponível no momento.</p>';
      }

      // Card Metrô
      if (data.metro_price && data.metro_price > 0) {
        html += `
          <div class="option-card">
            <div class="option-details">
              <div class="option-icon-title">
                <i class="fa-solid fa-train-subway option-icon"></i>
                <span class="option-title" style="color: yellow;">Metrô</span>
              </div>
              <span class="option-price" style="color: yellow;">R$ ${data.metro_price.toFixed(2).replace('.', ',')}</span>
            </div>
          </div>
        `;
      } else {
        html += '<p>Preço do Metrô não disponível no momento.</p>';
      }

      optionsSection.innerHTML = html;
    }

    // Atualizar o mapa
    if (data.origin && data.destination && data.drive_polyline && data.transit_polyline) {
      const mapContainer = document.getElementById("map-container");
      mapContainer.innerHTML = `
        <div data-controller="map" id="map" class="map-container whole-map" style="height: 100%; width: 100%;"
             data-map-origin-value='${JSON.stringify(data.origin)}'
             data-map-destination-value='${JSON.stringify(data.destination)}'
             data-map-drive-value='${data.drive_polyline}'
             data-map-transit-value='${data.transit_polyline}'
             data-map-key-value='${data.map_key}'>
        </div>
      `;
      // Reativar o controlador Stimulus para o mapa
      if (window.Stimulus) {
        Stimulus.controllers.forEach(controller => {
          if (controller.identifier === "map") {
            controller.connect();
          }
        });
      }
    }
  };

  // Fazer uma requisição AJAX inicial para obter os dados mais recentes
  fetch(`/rides/${rideId}/ride_data`, {
    headers: {
      "Accept": "application/json"
    }
  })
    .then(response => response.json())
    .then(data => {
      console.log("Dados recebidos da requisição AJAX inicial:", data);
      if (data.distance && data.duration) {
        updatePage(data);
      }
    })
    .catch(error => {
      console.error("Erro ao buscar dados iniciais:", error);
    });

  // Conectar ao RideChannel para atualizações em tempo real
  consumer.subscriptions.create(
    { channel: "RideChannel", ride_id: rideId },
    {
      connected() {
        console.log(`Conectado ao RideChannel para o ride ${rideId}`);
      },
      disconnected() {
        console.log(`Desconectado do RideChannel para o ride ${rideId}`);
      },
      received(data) {
        console.log("Dados recebidos via ActionCable:", data);
        updatePage(data);
      }
    }
  );
});
