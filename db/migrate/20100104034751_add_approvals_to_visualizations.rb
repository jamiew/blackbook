class AddApprovalsToVisualizations < ActiveRecord::Migration
  def self.up
    add_column :visualizations, :approved_at, :datetime
    add_column :visualizations, :approved_by, :integer
  end

  def self.down
    remove_column :visualizations, :approved_by
    remove_column :visualizations, :approved_at
  end
end
