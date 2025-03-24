class DestinationsController < ApplicationController
  def index
    @destinations = Destination.all
  end

  def test
  @destination = Destination.find(params[:id])

end


end
