class GmlObject < ActiveRecord::Base

  belongs_to :tag

  validates_presence_of :tag_id, :on => :create, :message => "must have a tag_id"
  validates_uniqueness_of :tag_id, :on => :create, :message => "must be unique"
  validates_associated :tag, :on => :create

  # FIXME temporarily allowing blank data...
  # Need to make the process a little more clear; FIXME. Also some magic in TagsController to link into this
  # validates_presence_of :data, :on => :create, :message => "can't be blank"

  # TODO Wrappers to inflate/deflate our data attribute
  # TODO we should also attr_protected :data to prevent getting around this...
  # def data
  #   return self.attributes['data'] if self.attributes['data'].blank?
  #   @uncompressed_data ||= Zlib::Inflate.new.inflate(self.attributes['data'])
  # end
  #
  # def _data=(fresh)
  #   # self.attributes['data'] = Zlib::Deflate.new.deflate(fresh)
  #   encoded = Zlib::Deflate.new.deflate(fresh)
  #   # self.attributes['data'] = encoded
  #   self.data = encoded
  # end

  # TODO validate GML here instead of Tag
  # can also do header extraction and such
  # as well as to_json? not sure.

end
