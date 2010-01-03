class AddFieldsToVisualizations < ActiveRecord::Migration
  def self.up
    add_column :visualizations, :kind, :string, :default => '' # possibly rename to :language -- Flash, javascript, c++ etc; 
    add_column :visualizations, :is_embeddable, :boolean, :default => false
    add_column :visualizations, :embed_url, :string
  end

  def self.down
    remove_column :visualizations, :kind
    remove_column :visualizations, :is_embeddable
    remove_column :visualizations, :embed_url
  end
end
