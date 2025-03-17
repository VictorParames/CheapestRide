class ChangePickupLngToFloat2 < ActiveRecord::Migration[7.1]
  def change
    remove_column :rides, :pickup_lng, :string
    add_column :rides, :pickup_lng, :float
  end
end
