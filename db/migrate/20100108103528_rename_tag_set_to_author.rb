class RenameTagSetToAuthor < ActiveRecord::Migration
  def self.up
    rename_column :tags, :set, :author
  end

  def self.down
    rename_column :tags, :author, :set
  end
end
