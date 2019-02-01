class AddFieldsToVisualizations < ActiveRecord::Migration
  def self.up
    add_column :visualizations, :authors, :string
    add_column :visualizations, :kind, :string, default: '' # possibly rename to :language -- Flash, javascript, c++ etc;
    add_column :visualizations, :is_embeddable, :boolean, default: false
    add_column :visualizations, :embed_url, :string
    add_column :visualizations, :embed_callback, :string
    add_column :visualizations, :embed_params, :string
    add_column :visualizations, :embed_code, :mediumtext # Allow medium-sized applications; 16 million chars; longtext is 4 billion...

  end

  def self.down
    remove_column :visualizations, :authors
    remove_column :visualizations, :kind
    remove_column :visualizations, :is_embeddable
    remove_column :visualizations, :embed_url
    remove_column :visualizations, :embed_callback
    remove_column :visualizations, :embed_params
    remove_column :visualizations, :embed_code
  end
end
