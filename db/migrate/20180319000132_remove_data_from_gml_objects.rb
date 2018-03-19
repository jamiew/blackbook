class RemoveDataFromGmlObjects < ActiveRecord::Migration
  def change
    remove_column :gml_objects, :data
  end
end
