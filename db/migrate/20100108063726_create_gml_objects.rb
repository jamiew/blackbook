class CreateGmlObjects < ActiveRecord::Migration
  def self.up
    create_table :gml_objects do |t|
      t.integer :tag_id
      t.column :data, :longtext, :default => '' # up to 4 billion chars
      t.timestamps
    end
    add_index :gml_objects, :tag_id
    # ^^possibly as a unique key? Going to do this model-level -- don't want dupes accidentally
    
    # bootstrap tags
    Tag.all.each { |v| v.send(:create_gml_object) rescue "failed: #{$!}" }
    
    # remove the Tag GML column (!!!)
    remove_column :tags, :gml
    
  end

  def self.down
    # drop_table :gml_objects
    drop_table :gmls
  end
end
