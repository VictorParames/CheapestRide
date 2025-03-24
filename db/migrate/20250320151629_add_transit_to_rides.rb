class AddTransitToRides < ActiveRecord::Migration[7.1]
  def change
    add_column :rides, :transit_polyline, :string
  end
end
