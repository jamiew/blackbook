class GML_Object < ActiveRecord::Base
  
   belongs_to :tag
    
  validates_presence_of :tag_id, :on => :create, :message => "must have a tag_id"
  validates_uniqueness_of :tag_id, :on => :create, :message => "must be unique; currently a Tag can only have one (1) GML object"  
  validates_associated :tag, :on => :create
  validates_presence_of :data, :on => :create, :message => "can't be blank"
  
  #TODO: validate GML here instead of Tag
  # can also do header extraction and such
  # as well as to_json? not sure.
end
