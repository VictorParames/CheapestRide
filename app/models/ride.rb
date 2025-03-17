class Ride < ApplicationRecord
  belongs_to :user
  geocoded_by :dropoff, latitude: :dropoff_lat, longitude: :dropoff_lng
  geocoded_by :pickup, latitude: :pickup_lat, longitude: :pickup_lng
  after_validation :geocode
end
