# app/channels/ride_channel.rb
class RideChannel < ApplicationCable::Channel
  def subscribed
    stream_from "ride:#{params[:ride_id]}"
    Rails.logger.info("Client subscribed to ride:#{params[:ride_id]}")
  end

  def unsubscribed
    Rails.logger.info("Client unsubscribed from ride:#{params[:ride_id]}")
  end
end
