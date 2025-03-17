class CreateRides < ActiveRecord::Migration[7.1]
  def change
    create_table :rides do |t|
      t.text :dropoff
      t.float :dropoff_lat
      t.float :dropoff_lng
      t.text :pickup
      t.float :pickup_lat
      t.string :pickup_lng_float
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
  end
end
