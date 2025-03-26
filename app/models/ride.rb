# app/models/ride.rb
class Ride < ApplicationRecord
  belongs_to :user

  # Enfileirar o job para calcular as rotas após a criação
  # after_create :enqueue_route_calculation

  private

  def enqueue_route_calculation
    CalculateRideRoutesJob.perform_later(self)
  end
end
