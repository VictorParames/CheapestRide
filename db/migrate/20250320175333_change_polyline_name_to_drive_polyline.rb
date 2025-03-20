class ChangePolylineNameToDrivePolyline < ActiveRecord::Migration[7.1]
  def change
    rename_column :rides, :polyline, :drive_polyline
  end
end
