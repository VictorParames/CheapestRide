class CreateDestinations < ActiveRecord::Migration[7.1]
  def change
    create_table :destinations do |t|
      t.text :dropoff_location
      t.float :latitude
      t.float :longitude

      t.timestamps
    end
  end
end
