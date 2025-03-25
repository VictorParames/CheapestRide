class AddDefaultAvatarToUser < ActiveRecord::Migration[7.1]
  def change
    change_column_default :users, :avatar, "Avatar-5"
  end
end
