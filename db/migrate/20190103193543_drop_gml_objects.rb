class DropGmlObjects < ActiveRecord::Migration
  def change
    drop_table :gml_objects
  end
end
