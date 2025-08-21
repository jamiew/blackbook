class RemoveIpfsFromTags < ActiveRecord::Migration[8.0]
  def change
    remove_column :tags, :ipfs_hash, :string
    remove_column :tags, :size, :integer
  end
end
