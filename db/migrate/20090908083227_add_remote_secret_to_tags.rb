class AddRemoteSecretToTags < ActiveRecord::Migration
  def self.up
    add_column :tags, :remote_secret, :string
  end

  def self.down
    remove_column :tags, :remote_secret
  end
end
