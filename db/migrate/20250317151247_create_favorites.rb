class CreateFavorites < ActiveRecord::Migration[7.1]
  def change
    create_table :favorites do |t|
      t.text :location
      t.float :location_lat
      t.float :location_lng
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
  end
end
