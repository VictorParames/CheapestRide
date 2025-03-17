class Ride < ApplicationRecord
  belongs_to :user
  #geocoded_by :dropoff, latitude: :dropoff_lat, longitude: :dropoff_lng
  #geocoded_by :pickup, latitude: :pickup_lat, longitude: :pickup_lng



  after_validation :find_geocode

  private

  def find_geocode
    results = Geocoder.search(pickup)
    self.pickup_lat = results.first.coordinates[0]
    self.pickup_lng = results.first.coordinates[1]
    results = Geocoder.search(dropoff)
    self.dropoff_lat = results.first.coordinates[0]
    self.dropoff_lng = results.first.coordinates[1]
  end

  #after_validation :geocode
end
