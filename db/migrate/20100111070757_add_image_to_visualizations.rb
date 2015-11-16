class AddImageToVisualizations < ActiveRecord::Migration
  def self.up
    add_column :visualizations, :image_file_name, :string
    add_column :visualizations, :image_content_type, :string
    add_column :visualizations, :image_file_size, :integer
  end

  def self.down
    remove_column :visualizations, :image_file_size
    remove_column :visualizations, :image_content_type
    remove_column :visualizations, :image_file_name
  end
end
