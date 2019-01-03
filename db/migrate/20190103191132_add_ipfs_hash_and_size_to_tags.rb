class MoveIpfsHashAndSizeFromGmlObjectToTag < ActiveRecord::Migration
  def change
    add_column :tags, :size, :integer
    add_column :tags, :ipfs_hash, :string
  end

end
