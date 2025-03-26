# app/controllers/rides_controller.rb
class RidesController < ApplicationController
  before_action :set_ride, only: [:show, :ride_data]

  def index
    @ride = Ride.new
  end

  def show
    @pickup_location = extract_street_name(@ride.pickup)
    @dropoff_location = extract_street_name(@ride.dropoff)
    @distance = @ride.distance
    @duration = @ride.duration
    @drive_polyline = @ride.drive_polyline
    @transit_polyline = @ride.transit_polyline
    @origin = [@ride.pickup_lat, @ride.pickup_lng]
    @destination = [@ride.dropoff_lat, @ride.dropoff_lng]

    # Usar os preços salvos no Ride (calculados pelo CalculateRideRoutesJob)
    @uber_price = @ride.uber_price
    @ninetynine_price = @ride.ninetynine_price
    @indrive_price = @ride.indrive_price
    @metro_price = @ride.metro_price
  end

  def ride_data
    render json: {
      distance: @ride.distance,
      duration: @ride.duration,
      uber_price: @ride.uber_price,
      ninetynine_price: @ride.ninetynine_price,
      indrive_price: @ride.indrive_price,
      metro_price: @ride.metro_price,
      origin: [@ride.pickup_lat, @ride.pickup_lng],
      destination: [@ride.dropoff_lat, @ride.dropoff_lng],
      drive_polyline: @ride.drive_polyline,
      transit_polyline: @ride.transit_polyline,
      map_key: ENV["MAPS_KEY"]
    }
  end

  def new
    @ride = Ride.new
  end

  def create
    pickup = params[:ride][:pickup].presence
    dropoff = params[:ride][:dropoff].presence

    if pickup.nil? || dropoff.nil?
      @ride = Ride.new(ride_params)
      flash.now[:alert] = "Por favor, preencha os campos de origem e destino."
      render :new, status: :unprocessable_entity
      return
    end

    @ride = Ride.new(ride_params)
    @ride.user = current_user
    if @ride.save
      CalculateRideRoutesJob.perform_now(@ride)
      redirect_to @ride, notice: "Ride was successfully created."
    else
      flash.now[:alert] = @ride.errors.full_messages.to_sentence
      render :new, status: :unprocessable_entity
    end
  end

  private

  def set_ride
    @ride = Ride.find_by(id: params[:id])
    unless @ride
      redirect_to rides_path, alert: "Corrida não encontrada."
    end
  end

  def ride_params
    params.require(:ride).permit(:pickup, :dropoff)
  end

  def extract_street_name(address)
    return "" if address.blank?

    address.split(",").first.strip
  end
end
