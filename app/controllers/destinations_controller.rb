class DestinationsController < ApplicationController
  def index
    @destinations = Destination.all
  end

  def show
  @ride = Ride.find(params[:id])
  @origin = [@ride.pickup_lat, @ride.pickup_lng]
  @destination = params[:destination]



  end

  def new
    @destination = Destination.new
  end

  def create
    @destination = Destination.new(destination_params)
    if @destination.save
      redirect_to destination_path(@destination)
    else
      render :new
    end
  end

  private

  def destination_params
    params.require(:destination).permit(:name, :country)
  end
end
