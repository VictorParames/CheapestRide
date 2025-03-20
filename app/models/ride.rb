require "rest-client"

class Ride < ApplicationRecord
  belongs_to :user
  after_validation :set_coordinates

  def calculate_route_to_station
    return unless nearest_metro_station_lat && nearest_metro_station_lng

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
            latitude: nearest_metro_station_lat,
            longitude: nearest_metro_station_lng
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
      'X-Goog-FieldMask': 'routes.duration,routes.distanceMeters'
    }
    response = RestClient.post(url, body.to_json, headers)
    parsed_response = JSON.parse(response)

    {
      distance: parsed_response["routes"][0]["distanceMeters"].to_f / 1000, # Converter para km
      duration: parsed_response["routes"][0]["duration"].delete("s").to_f / 60 # Converter para minutos
    }
  end

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
    response = RestClient.post(url, body.to_json, headers)
    parsed_response = JSON.parse(response)

    self.distance = parsed_response["routes"][0]["distanceMeters"]
    self.duration = parsed_response["routes"][0]["duration"]
    self.drive_polyline = parsed_response["routes"][0]["polyline"]["encodedPolyline"]
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
      'X-Goog-FieldMask': 'routes.polyline'
    }
    response = RestClient.post(url, body.to_json, headers)
    parsed_response = JSON.parse(response)
    self.transit_polyline = parsed_response["routes"][0]["polyline"]["encodedPolyline"]

    if parsed_response["routes"].present? && parsed_response["routes"][0]["duration"].present?
      self.transit_distance = parsed_response["routes"][0]["distanceMeters"].to_f / 1000
      self.transit_duration = parsed_response["routes"][0]["duration"].to_s.delete("s").to_f / 60
    else
      Rails.logger.error("Erro na API: Resposta inesperada para a rota de transporte público: #{parsed_response}")
      self.transit_distance = nil
      self.transit_duration = nil
    end

    if parsed_response["routes"].present? && parsed_response["routes"][0]["legs"].present?
      steps = parsed_response["routes"][0]["legs"][0]["steps"]
      metro_step = steps.find do |step|
        step["travelMode"] == "TRANSIT" && step.dig("transitDetails", "line", "vehicle", "type") == "SUBWAY"
      end

      if metro_step
        stop = metro_step["transitDetails"]["stop"]
        self.nearest_metro_station_lat = stop["location"]["latLng"]["latitude"]
        self.nearest_metro_station_lng = stop["location"]["latLng"]["longitude"]
      end
    else
      Rails.logger.error("Erro na API: Resposta inesperada ou sem rotas disponíveis: #{parsed_response}")
    end
  end

  def find_geocode
    results = Geocoder.search(pickup)
    self.pickup_lat = results.first.coordinates[0]
    self.pickup_lng = results.first.coordinates[1]
    results = Geocoder.search(dropoff)
    self.dropoff_lat = results.first.coordinates[0]
    self.dropoff_lng = results.first.coordinates[1]
  end
end
