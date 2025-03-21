class HomeController < ApplicationController
  layout "home"

  def index
  end

  def index
    @ride = Ride.new  # Certifique-se de que Ride é o modelo correto
  end



end
