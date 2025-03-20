class AddDistanceAndDurationToRides < ActiveRecord::Migration[7.1]
  def change
    add_column :rides, :distance, :integer
    add_column :rides, :duration, :string
  end
end
