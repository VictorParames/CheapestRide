# app/controllers/rides_controller.rb
class RidesController < ApplicationController
  before_action :authenticate_user!, only: [:create] # Garante que o usuário está autenticado
  before_action :set_ride, only: [:show]

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

    # Calcular preços apenas se distance e duration estiverem disponíveis
    if @distance && @duration
      price_service = RidePriceService.new(@distance, @duration)
      @uber_price = price_service.fetch_full_ride_price("Uber")
      @ninetynine_price = price_service.fetch_full_ride_price("99")
      @indrive_price = price_service.fetch_full_ride_price("InDrive")
    else
      @uber_price = nil
      @ninetynine_price = nil
      @indrive_price = nil
    end

    # Preço fixo do metrô
    @metro_price = @ride.transit_distance && @ride.transit_distance > 0 ? 5.20 : nil
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
