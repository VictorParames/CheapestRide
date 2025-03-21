class AddNearestMetroStationToRides < ActiveRecord::Migration[7.1]
  def change
    add_column :rides, :nearest_metro_station_lat, :float
    add_column :rides, :nearest_metro_station_lng, :float
  end
end
