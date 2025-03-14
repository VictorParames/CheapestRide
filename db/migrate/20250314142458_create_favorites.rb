class CreateFavorites < ActiveRecord::Migration[7.1]
  def change
    create_table :favorites do |t|
      t.references :profile, null: false, foreign_key: true
      t.text :location_name
      t.float :latitude
      t.float :longitude

      t.timestamps
    end
  end
end
