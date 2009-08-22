class ModTagFields < ActiveRecord::Migration
  def self.up
    add_column :tags, :uuid, :string    
    add_column :tags, :ip, :string
    rename_column :tags, :description, :gml
  end

  def self.down
    remove_column :tags, :uuid
    remove_column :tags, :ip
    rename_column :tags, :gml, :description
  end
end
