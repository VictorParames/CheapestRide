class Ride < ApplicationRecord
  belongs_to :profile
  belongs_to :destination
end
