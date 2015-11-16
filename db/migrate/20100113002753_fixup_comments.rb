class FixupComments < ActiveRecord::Migration
  def self.up
    rename_column :comments, :comment, :text
    add_column :comments, :ip_address, :string
    add_column :comments, :hidden_at, :datetime

    # # denormalization columns -- largely for activity feeds yheard
    # add_column :comments, :cached_user_login, :string
    # add_column :comments, :cached_user_url, :string
  end

  def self.down
    rename_column :comments, :text, :comment
    remove_column :comments, :ip_address
    remove_column :comments, :hidden_at

    # remove_column :comments, :cached_user_login
    # remove_column :comments, :cached_user_url
  end
end
