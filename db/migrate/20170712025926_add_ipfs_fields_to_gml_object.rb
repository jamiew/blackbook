class AddIpfsFieldsToGmlObject < ActiveRecord::Migration
  def change
    add_column :gml_objects, :size, :integer
    add_column :gml_objects, :ipfs_hash, :string
    add_column :gml_objects, :ipfs_created_at, :datetime
    add_column :gml_objects, :ipfs_modified_at, :datetime
  end
end
