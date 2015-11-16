class AddLocationToTag < ActiveRecord::Migration
  def self.up
    add_column :tags, :location, :string
    add_column :tags, :application, :string
    add_column :tags, :set, :string
    add_column :tags, :cached_tag_list, :string
  end

  def self.down
    remove_column :tags, :location
    remove_column :tags, :application
    remove_column :tags, :set
    remove_column :tags, :cached_tag_list
  end
end
