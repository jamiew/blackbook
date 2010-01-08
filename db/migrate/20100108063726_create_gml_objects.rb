class CreateGmlObjects < ActiveRecord::Migration
  def self.up
    create_table :gml_objects do |t|
      t.integer :tag_id
      t.column :data, :longtext
      # ^^ we might want to store as a large BLOB and actually COMPRESS()/UNCOMPRESS() coming in & out...?
      #   have some code to do exactly that started in gml_object.rb, but it's acting up. Like to use native MySQL if we can? faster
      t.timestamps
    end
    add_index :gml_objects, :tag_id
    # ^^possibly as a unique key? Going to do this model-level -- don't want dupes accidentally
    
    # bootstrap Tag.gml => GMLObject
    Tag.all.each { |v| 
      begin
        v.send(:create_gml_object) 
      rescue 
        puts "Failed: #{$!}" 
      end
    }
    
    # remove the Tag GML column (!!!)
    remove_column :tags, :gml    
  end

  def self.down
    drop_table :gml_objects
  end
end
