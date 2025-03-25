class AddPricesToRides < ActiveRecord::Migration[7.1]
  def change
    add_column :rides, :uber_price, :decimal
    add_column :rides, :ninetynine_price, :decimal
    add_column :rides, :indrive_price, :decimal
    add_column :rides, :metro_price, :decimal
  end
end
