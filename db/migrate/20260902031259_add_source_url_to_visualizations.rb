class AddSourceUrlToVisualizations < ActiveRecord::Migration[8.1]
  def change
    add_column :visualizations, :source_url, :string
  end
end
