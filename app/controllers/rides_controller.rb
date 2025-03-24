# app/controllers/rides_controller.rb
class RidesController < ApplicationController
  def index
    @ride = Ride.new
  end

  def show
    ride = Ride.find(params[:id])
    @origin = [ride.pickup_lat, ride.pickup_lng]
    @destination = [ride.dropoff_lat, ride.dropoff_lng]
    @pickup_location = extract_street_name(ride.pickup)
    @dropoff_location = extract_street_name(ride.dropoff)
    @distance = ride.distance
    @drive_polyline = ride.drive_polyline
    @transit_polyline = ride.transit_polyline
  end

  def new
    @ride = Ride.new
  end

  def create
    pickup = params[:ride][:pickup].presence
    dropoff = params[:ride][:dropoff].presence

    unless pickup.nil? || dropoff.nil?
      @ride = Ride.new(ride_params)
      @ride.user = current_user
      if @ride.save!
        redirect_to @ride, notice: "Ride was successfully created."
      else
        render :new, status: :unprocessable_entity
      end
    end

  end

  private

  def ride_params
    params.require(:ride).permit(:pickup, :dropoff)
  end

  def extract_street_name(address)
    return "" if address.blank?

    address.split(",").first.strip
  end
end
