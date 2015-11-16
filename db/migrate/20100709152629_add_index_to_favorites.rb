class AddIndexToFavorites < ActiveRecord::Migration
  def self.up
    add_index :favorites, [:object_id, :object_type]
  end

  def self.down
    remove_index :favorites, [:object_id, :object_type]
  end
end
