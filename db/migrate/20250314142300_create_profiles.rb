class CreateProfiles < ActiveRecord::Migration[7.1]
  def change
    create_table :profiles do |t|
      t.references :user, null: false, foreign_key: true
      t.text :pickup_location
      t.float :latitude
      t.float :longitude

      t.timestamps
    end
  end
end
