# app/jobs/calculate_ride_routes_job.rb
class CalculateRideRoutesJob < ApplicationJob
  queue_as :default

  def perform(ride)
    # Carregar dependências
    require "rest-client"

    # Inicializar valores padrão para evitar erros
    ride.update(
      pickup_lat: nil,
      pickup_lng: nil,
      dropoff_lat: nil,
      dropoff_lng: nil,
      distance: 0.0,
      duration: 0,
      drive_polyline: "",
      transit_distance: 0.0,
      transit_duration: 0,
      transit_polyline: "",
      nearest_metro_station_lat: nil,
      nearest_metro_station_lng: nil
    )

    # Executar os cálculos
    find_geocode(ride)
    return unless ride.errors.empty? # Para se houver erro no geocoding

    get_route_drive(ride)
    get_route_transit(ride)

    # Após atualizar o Ride, transmitir os dados pelo ActionCable
    broadcast_update(ride)
  end

  private

  def broadcast_update(ride)
    # Preparar os dados para enviar ao cliente
    data = {
      distance: ride.distance,
      duration: ride.duration,
      uber_price: calculate_uber_price(ride.distance),
      ninetynine_price: calculate_99_price(ride.distance),
      indrive_price: calculate_indrive_price(ride.distance),
      metro_price: calculate_metro_price(ride.transit_distance),
      origin: [ride.pickup_lat, ride.pickup_lng],
      destination: [ride.dropoff_lat, ride.dropoff_lng],
      drive_polyline: ride.drive_polyline,
      transit_polyline: ride.transit_polyline,
      map_key: ENV["MAPS_KEY"]
    }

    # Transmitir os dados pelo canal específico do ride
    ActionCable.server.broadcast("ride:#{ride.id}", data)
  end

  def calculate_uber_price(distance)
    # Lógica fictícia para calcular o preço do Uber
    (distance * 2.5).round(2) # Exemplo: R$2,50 por km
  end

  def calculate_99_price(distance)
    # Lógica fictícia para calcular o preço do 99
    (distance * 2.0).round(2) # Exemplo: R$2,00 por km
  end

  def calculate_indrive_price(distance)
    # Lógica fictícia para calcular o preço do InDrive
    (distance * 1.8).round(2) # Exemplo: R$1,80 por km
  end

  def calculate_metro_price(transit_distance)
    # Lógica fictícia para calcular o preço do Metrô
    transit_distance > 0 ? 4.40 : 0 # Exemplo: tarifa fixa de R$4,40 em São Paulo
  end

  def find_geocode(ride)
    begin
      results = Geocoder.search(ride.pickup)
      if results.first&.coordinates
        ride.update(
          pickup_lat: results.first.coordinates[0],
          pickup_lng: results.first.coordinates[1]
        )
      else
        Rails.logger.error("Geocoder failed to find coordinates for pickup: #{ride.pickup}")
        ride.errors.add(:pickup, "não pôde ser encontrado")
        return
      end

      results = Geocoder.search(ride.dropoff)
      if results.first&.coordinates
        ride.update(
          dropoff_lat: results.first.coordinates[0],
          dropoff_lng: results.first.coordinates[1]
        )
      else
        Rails.logger.error("Geocoder failed to find coordinates for dropoff: #{ride.dropoff}")
        ride.errors.add(:dropoff, "não pôde ser encontrado")
        return
      end
    rescue StandardError => e
      Rails.logger.error("Geocoder error: #{e.message}")
      ride.errors.add(:base, "Erro ao buscar coordenadas. Tente novamente mais tarde.")
    end
  end

  def get_route_drive(ride)
    url = "https://routes.googleapis.com/directions/v2:computeRoutes"
    body = {
      origin: {
        location: {
          latLng: {
            latitude: ride.pickup_lat,
            longitude: ride.pickup_lng
          }
        }
      },
      destination: {
        location: {
          latLng: {
            latitude: ride.dropoff_lat,
            longitude: ride.dropoff_lng
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
    }
    headers = {
      'Content-Type': 'application/json',
      'X-Goog-Api-Key': ENV.fetch("MAPS_KEY"),
      'X-Goog-FieldMask': 'routes.duration,routes.distanceMeters,routes.polyline.encodedPolyline'
    }
    begin
      response = RestClient.post(url, body.to_json, headers)
      parsed_response = JSON.parse(response)
      if parsed_response["routes"]&.any?
        distance_meters = parsed_response["routes"][0]["distanceMeters"].to_f
        distance = (distance_meters / 1000.0).round(2) # Converter metros para km
        duration = (parsed_response["routes"][0]["duration"].delete("s").to_f / 60).round # Arredondar para número inteiro
        drive_polyline = parsed_response["routes"][0]["polyline"]["encodedPolyline"]
        ride.update(
          distance: distance,
          duration: duration,
          drive_polyline: drive_polyline
        )
        Rails.logger.info("Driving route - Distance: #{distance} km (#{distance_meters} meters), Duration: #{duration} minutes")
      else
        Rails.logger.warn("No driving route found: #{parsed_response}")
        ride.update(distance: 0.0, duration: 0, drive_polyline: "")
      end
    rescue RestClient::ExceptionWithResponse => e
      Rails.logger.error("Failed to get driving route: #{e.message}")
      ride.update(distance: 0.0, duration: 0, drive_polyline: "")
    end
  end

  def get_route_transit(ride)
    url = "https://routes.googleapis.com/directions/v2:computeRoutes"
    body = {
      origin: {
        location: {
          latLng: {
            latitude: ride.pickup_lat,
            longitude: ride.pickup_lng
          }
        }
      },
      destination: {
        location: {
          latLng: {
            latitude: ride.dropoff_lat,
            longitude: ride.dropoff_lng
          }
        }
      },
      travelMode: 'TRANSIT',
      computeAlternativeRoutes: true
    }
    headers = {
      'Content-Type': 'application/json',
      'X-Goog-Api-Key': ENV.fetch("MAPS_KEY"),
      'X-Goog-FieldMask': 'routes.duration,routes.distanceMeters,routes.polyline.encodedPolyline,routes.legs.steps'
    }
    begin
      response = RestClient.post(url, body.to_json, headers)
      parsed_response = JSON.parse(response)
      Rails.logger.info("Transit route response: #{parsed_response.inspect}")

      if parsed_response["routes"]&.any?
        route = parsed_response["routes"][0]
        transit_polyline = route.dig("polyline", "encodedPolyline") || ""
        distance_meters = route["distanceMeters"].to_f
        transit_distance = (distance_meters / 1000.0).round(2) # Converter para km
        transit_duration = ((route["duration"]&.delete("s")&.to_f || 0) / 60).round # Arredondar para número inteiro

        steps = route.dig("legs", 0, "steps") || []
        metro_step = steps.find do |step|
          step["travelMode"] == "TRANSIT" && step.dig("transitDetails", "line", "vehicle", "type") == "SUBWAY"
        end

        if metro_step
          stop = metro_step.dig("transitDetails", "stop")
          nearest_metro_station_lat = stop&.dig("location", "latLng", "latitude")
          nearest_metro_station_lng = stop&.dig("location", "latLng", "longitude")
          ride.update(
            transit_polyline: transit_polyline,
            transit_distance: transit_distance,
            transit_duration: transit_duration,
            nearest_metro_station_lat: nearest_metro_station_lat,
            nearest_metro_station_lng: nearest_metro_station_lng
          )
          Rails.logger.info("Nearest metro station: (#{nearest_metro_station_lat}, #{nearest_metro_station_lng})")
        else
          Rails.logger.warn("No subway step found in transit route: #{parsed_response}")
          # Fallback: Usar uma estação de metrô próxima
          set_nearest_metro_station_fallback(ride)
          ride.update(
            transit_polyline: transit_polyline,
            transit_distance: transit_distance,
            transit_duration: transit_duration
          )
        end
      else
        Rails.logger.warn("No transit routes found for pickup: #{ride.pickup}, dropoff: #{ride.dropoff}")
        ride.update(transit_polyline: "", transit_distance: 0, transit_duration: 0)
        # Fallback: Usar uma estação de metrô próxima
        set_nearest_metro_station_fallback(ride)
      end
    rescue RestClient::ExceptionWithResponse => e
      Rails.logger.error("Failed to get transit route: #{e.message}")
      ride.update(transit_polyline: "", transit_distance: 0, transit_duration: 0)
      # Fallback: Usar uma estação de metrô próxima
      set_nearest_metro_station_fallback(ride)
    end
  end

  def set_nearest_metro_station_fallback(ride)
    # Lista estática de estações de metrô em São Paulo (latitude, longitude)
    metro_stations = [
      { name: "Estação Sé", lat: -23.5505, lng: -46.6333 },
      { name: "Estação Consolação", lat: -23.5578, lng: -46.6607 },
      { name: "Estação Vila Madalena", lat: -23.5465, lng: -46.6908 },
      { name: "Estação Santo Amaro", lat: -23.6545, lng: -46.7192 },
      { name: "Estação Faria Lima", lat: -23.5670, lng: -46.6900 },
      # Adicione mais estações conforme necessário
    ]

    # Encontrar a estação mais próxima do ponto de origem (pickup)
    nearest_station = metro_stations.min_by do |station|
      distance = Geocoder::Calculations.distance_between(
        [ride.pickup_lat, ride.pickup_lng],
        [station[:lat], station[:lng]]
      )
      distance
    end

    if nearest_station
      ride.update(
        nearest_metro_station_lat: nearest_station[:lat],
        nearest_metro_station_lng: nearest_station[:lng]
      )
      Rails.logger.info("Using fallback metro station: #{nearest_station[:name]} (#{nearest_station[:lat]}, #{nearest_station[:lng]})")
    else
      Rails.logger.warn("No fallback metro station found.")
      ride.update(nearest_metro_station_lat: nil, nearest_metro_station_lng: nil)
    end
  end
end
