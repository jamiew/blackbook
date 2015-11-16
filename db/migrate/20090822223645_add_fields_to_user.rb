class AddFieldsToUser < ActiveRecord::Migration
  def self.up
    #  website            :string(255)
    #  tagline            :string(255)
    #  about              :text
    #  location           :string(255)
    #  slug               :string(255)

    add_column :users, :website, :string
    add_column :users, :tagline, :string
    add_column :users, :about, :text
    add_column :users, :location, :string
    add_column :users, :slug, :string
  end

  def self.down
    remove_column :users, :website
    remove_column :users, :tagline
    remove_column :users, :about
    remove_column :users, :location
    remove_column :users, :slug
  end
end
