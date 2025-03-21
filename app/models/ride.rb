# app/models/ride.rb
require "rest-client"

class Ride < ApplicationRecord
  belongs_to :user
  after_validation :set_coordinates

  private

  def set_coordinates
    find_geocode
    get_route_drive
    get_route_transit
  end

  def get_route_drive
    url = "https://routes.googleapis.com/directions/v2:computeRoutes"
    body = {
      origin: {
        location: {
          latLng: {
            latitude: pickup_lat,
            longitude: pickup_lng
          }
        }
      },
      destination: {
        location: {
          latLng: {
            latitude: dropoff_lat,
            longitude: dropoff_lng
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
        self.distance = (distance_meters / 1000.0).round(2) # Converter metros para km
        self.duration = (parsed_response["routes"][0]["duration"].delete("s").to_f / 60).round(2) # Converter segundos para minutos
        self.drive_polyline = parsed_response["routes"][0]["polyline"]["encodedPolyline"]
        Rails.logger.info("Driving route - Distance: #{self.distance} km (#{distance_meters} meters), Duration: #{self.duration} minutes")
      else
        Rails.logger.warn("No driving route found: #{parsed_response}")
        self.distance = 0.0
        self.duration = 0.0
        self.drive_polyline = ""
      end
    rescue RestClient::ExceptionWithResponse => e
      Rails.logger.error("Failed to get driving route: #{e.message}")
      self.distance = 0.0
      self.duration = 0.0
      self.drive_polyline = ""
    end
  end

  def get_route_transit
    url = "https://routes.googleapis.com/directions/v2:computeRoutes"
    body = {
      origin: {
        location: {
          latLng: {
            latitude: pickup_lat,
            longitude: pickup_lng
          }
        }
      },
      destination: {
        location: {
          latLng: {
            latitude: dropoff_lat,
            longitude: dropoff_lng
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
        self.transit_polyline = route.dig("polyline", "encodedPolyline") || ""
        distance_meters = route["distanceMeters"].to_f
        self.transit_distance = (distance_meters / 1000.0).round(2) # Converter para km
        self.transit_duration = (route["duration"]&.delete("s")&.to_f || 0) / 60 # Converter para minutos

        steps = route.dig("legs", 0, "steps") || []
        metro_step = steps.find do |step|
          step["travelMode"] == "TRANSIT" && step.dig("transitDetails", "line", "vehicle", "type") == "SUBWAY"
        end

        if metro_step
          stop = metro_step.dig("transitDetails", "stop")
          self.nearest_metro_station_lat = stop&.dig("location", "latLng", "latitude")
          self.nearest_metro_station_lng = stop&.dig("location", "latLng", "longitude")
          Rails.logger.info("Nearest metro station: (#{self.nearest_metro_station_lat}, #{self.nearest_metro_station_lng})")
        else
          Rails.logger.warn("No subway step found in transit route: #{parsed_response}")
          # Fallback: Usar uma estação de metrô próxima
          set_nearest_metro_station_fallback
        end
      else
        Rails.logger.warn("No transit routes found for pickup: #{pickup}, dropoff: #{dropoff}")
        self.transit_polyline = ""
        self.transit_distance = 0
        self.transit_duration = 0
        # Fallback: Usar uma estação de metrô próxima
        set_nearest_metro_station_fallback
      end
    rescue RestClient::ExceptionWithResponse => e
      Rails.logger.error("Failed to get transit route: #{e.message}")
      self.transit_polyline = ""
      self.transit_distance = 0
      self.transit_duration = 0
      # Fallback: Usar uma estação de metrô próxima
      set_nearest_metro_station_fallback
    end
  end

  def set_nearest_metro_station_fallback
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
        [pickup_lat, pickup_lng],
        [station[:lat], station[:lng]]
      )
      distance
    end

    if nearest_station
      self.nearest_metro_station_lat = nearest_station[:lat]
      self.nearest_metro_station_lng = nearest_station[:lng]
      Rails.logger.info("Using fallback metro station: #{nearest_station[:name]} (#{nearest_station[:lat]}, #{nearest_station[:lng]})")
    else
      Rails.logger.warn("No fallback metro station found.")
      self.nearest_metro_station_lat = nil
      self.nearest_metro_station_lng = nil
    end
  end

  def find_geocode
    begin
      results = Geocoder.search(pickup)
      if results.first&.coordinates
        self.pickup_lat = results.first.coordinates[0]
        self.pickup_lng = results.first.coordinates[1]
      else
        Rails.logger.error("Geocoder failed to find coordinates for pickup: #{pickup}")
        self.errors.add(:pickup, "não pôde ser encontrado")
        throw(:abort)
      end

      results = Geocoder.search(dropoff)
      if results.first&.coordinates
        self.dropoff_lat = results.first.coordinates[0]
        self.dropoff_lng = results.first.coordinates[1]
      else
        Rails.logger.error("Geocoder failed to find coordinates for dropoff: #{dropoff}")
        self.errors.add(:dropoff, "não pôde ser encontrado")
        throw(:abort)
      end
    rescue StandardError => e
      Rails.logger.error("Geocoder error: #{e.message}")
      self.errors.add(:base, "Erro ao buscar coordenadas. Tente novamente mais tarde.")
      throw(:abort)
    end
  end
end
