class Profile < ApplicationRecord
  belongs_to :user
  has_many :rides
  has_many :favorites
  # has_many :destinations, through: :rides
end
