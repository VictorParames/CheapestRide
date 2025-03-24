class AddNotNullToPickupAndDropoff < ActiveRecord::Migration[7.1]
  def change
    change_column_null :rides, :pickup, false
    change_column_null :rides, :dropoff, false
  end
end
