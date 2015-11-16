class AddRemoteImageToTags < ActiveRecord::Migration
  def self.up
    add_column :tags, :remote_image, :string
  end

  def self.down
    remove_column :tags, :remote_image
  end
end
