class AddDescriptionToTag < ActiveRecord::Migration
  def self.up
    add_column :tags, :description, :text
  end

  def self.down
    remove_column :tags, :description
  end
end
