class ChangePickupLngToFloat < ActiveRecord::Migration[7.1]
  def change
    change_table :rides do |r|
      r.rename :pickup_lng_float, :pickup_lng
    end
  end
end
