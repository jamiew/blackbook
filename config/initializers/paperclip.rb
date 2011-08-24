# Smart ID partitioning so we don't exceed 65k files/links in one directory
# Usage:
#
#  has_attached_file :photo,
#    :styles => {:large => '600x600>', :medium => "300x300>", :small => '100x100#', :tiny => "32x32#"}
#    :default_style => :medium,
#    :default_url => "/photos/defaults/:style.jpg",
#    :url => "/photos/:id_smart/:basename_:style.:extension",
#    :path => ":rails_root/public/photos/:id_smart/:basename_:style.:extension"


Paperclip.interpolates(:id_smart) do |attachment, style|
  limit = 33600
  if attachment.instance.id > limit
    id_partition(attachment, style)
  else
    id(attachment, style)
  end
end
