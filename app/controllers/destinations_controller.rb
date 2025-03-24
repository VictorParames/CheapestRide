class DestinationsController < ApplicationController
  def index
    @destinations = Destination.all
  end

  def show
  @destination = Destination.find(params[:id])

end

def create

@destination = Destination.new(destination_params)

end


end
