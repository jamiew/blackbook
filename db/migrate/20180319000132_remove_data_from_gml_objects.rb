class RemoveDataFromGmlObjects < ActiveRecord::Migration
  def change
    remove_column :gml_objects, :data, :longtext
    remove_column :gml_objects, :ipfs_created_at, :datetime
    remove_column :gml_objects, :ipfs_modified_at, :datetime
  end
end
