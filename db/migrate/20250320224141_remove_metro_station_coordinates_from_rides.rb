class RemoveMetroStationCoordinatesFromRides < ActiveRecord::Migration[7.1]
  def change
    remove_column :rides, :nearest_metro_station_lat, :decimal
    remove_column :rides, :nearest_metro_station_lng, :decimal
  end
end
