class DenormalizeGmlHeaderToTag < ActiveRecord::Migration
  def self.up
    add_column :tags, :gml_application, :string
    add_column :tags, :gml_version, :string
    add_column :tags, :gml_username, :string
    add_column :tags, :gml_uniquekey, :string
    add_column :tags, :gml_uniquekey_hash, :string
    add_column :tags, :gml_keywords, :string
    # possibly index gml_application...
    # better to match application (application_id) to gml_application's string value on parsing
    # will need an aliases table to applications, possibly even users...
  end

  def self.down
    remove_column :tags, :gml_application, :string
    remove_column :tags, :gml_version, :string
    remove_column :tags, :gml_username, :string
    remove_column :tags, :gml_uniquekey, :string
    remove_column :tags, :gml_uniquekey_hash, :string    
    remove_column :tags, :gml_keywords
  end
end
