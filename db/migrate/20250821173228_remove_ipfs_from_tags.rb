class RemoveIpfsFromTags < ActiveRecord::Migration[7.1]
  def change
    remove_column :tags, :ipfs_hash, :string
  end
end
