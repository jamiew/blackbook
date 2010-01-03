class AddDatestampsToVisualizations < ActiveRecord::Migration
  def self.up
    add_column :visualizations, :created_at, :datetime
    add_column :visualizations, :updated_at, :datetime
  end

  def self.down
    remove_column :visualizations, :updated_at
    remove_column :visualizations, :created_at
  end
end
