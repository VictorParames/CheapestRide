class Ride < ApplicationRecord
  belongs_to :user
  #geocoded_by :dropoff, latitude: :dropoff_lat, longitude: :dropoff_lng
  #geocoded_by :pickup, latitude: :pickup_lat, longitude: :pickup_lng
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
