class AddIndexToUsersIphoneUniquekey < ActiveRecord::Migration
  def change
    add_index :users, :iphone_uniquekey
  end
end
