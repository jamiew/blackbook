class AddIphoneUniquekeyToUser < ActiveRecord::Migration
  def self.up
    add_column :users, :iphone_uniquekey, :string
  end

  def self.down
    remove_column :users, :iphone_uniquekey
  end
end
