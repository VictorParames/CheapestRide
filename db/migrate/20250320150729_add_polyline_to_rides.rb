class AddPolylineToRides < ActiveRecord::Migration[7.1]
  def change
    add_column :rides, :polyline, :string
  end
end
