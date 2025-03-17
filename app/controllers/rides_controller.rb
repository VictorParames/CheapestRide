class RidesController < ApplicationController

  def index
    @ride = Ride.new
  end
  def new
    @ride = Ride.new

  end
  def create
    @ride = Ride.new(ride_params)
    @ride.user = current_user
    if @ride.save
      redirect_to @ride, notice: "Ride was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def ride_params
    params.require(:ride).permit(:pickup, :dropoff)
  end
end
