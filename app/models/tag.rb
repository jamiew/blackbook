# == Schema Information
#
# Table name: tags
#
#  id                 :integer(4)      not null, primary key
#  user_id            :integer(4)
#  title              :string(255)
#  slug               :string(255)
#  gml                :text
#  comment_count      :integer(4)
#  likes_count        :integer(4)
#  created_at         :datetime
#  updated_at         :datetime
#  location           :string(255)
#  application        :string(255)
#  set                :string(255)
#  cached_tag_list    :string(255)
#  image_file_name    :string(255)
#  image_content_type :string(255)
#  image_file_size    :integer(4)
#  image_updated_at   :datetime
#  uuid               :string(255)
#  ip                 :string(255)
#  description        :text
#
# Indexes
#
#  index_on_slug  (slug)
#

class Tag < ActiveRecord::Base

  acts_as_commentable
  # is_taggable :tags
  # has_many :comments  
  
  belongs_to :user
  # has_many :comments
  has_many :likes
  
  validates_associated :user, :on => :create
  
  before_save :process_gml
  # before_save :process_app_id
  
  has_attached_file :image, 
    :default_style => :medium, 
    :styles => { :large => '600x600>', :medium => "300x300>", :small => '100x100#', :tiny => "32x32#" }
    # validates_attachment_presence :image
  
  after_create :create_notification
  
  def create_notification
    Notification.create(:subject => self, :verb => 'created')
  end
  
  
protected

  # extract some information from the GML
  # and insert our server signature
  def process_gml
    return nil if self.gml.blank?
    doc = Hpricot.XML(self.gml)
    header = (doc/'header')
    if header.blank?
      puts "No header in GML: #{self.gml}"
      return nil
    end

    attrs = {}
    attrs[:filename] = (header/'filename')[0].innerHTML rescue nil

    obj = (header/'client')[0] rescue nil
    attrs[:client] = (obj/'name').innerHTML

    puts "Tag.process_gml: #{attrs.inspect}"

    #TODO use hashes for all this, dry
    self.remote_image = attrs[:filename] unless attrs[:filename].blank?
    self.application = attrs[:client] unless attrs[:client].blank?
    return attrs    
  end
  
  # verify the specified secret, or else say unknown
  def process_app_id
    # TODO
  end
  
  
end
