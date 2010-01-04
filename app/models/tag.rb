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
#  remote_image       :string(255)
#  remote_secret      :string(255)
#

class Tag < ActiveRecord::Base

  #Blacklisted attributes not to show in the API
  #TODO: convert to a whitelisted approach...
  HIDDEN_ATTRIBUTES = [:ip, :user_id, :remote_secret]

  acts_as_commentable
  # is_taggable :tags
  # has_many :comments  
  
  belongs_to :user
  # has_many :comments
  has_many :likes
  
  validates_associated :user, :on => :create
  
  before_save :process_gml  
  before_create :validate_tempt
  # before_save :process_app_id
  
  # Security: protect from mass assignment
  attr_protected :user_id
    
  has_attached_file :image, 
    :default_style => :medium, 
    :styles => { :large => '600x600>', :medium => "300x300>", :small => '100x100#', :tiny => "32x32#" }
    # validates_attachment_presence :image
    
  # Placeholders for assigning data from forms  
  attr_accessor :gml_file, :existing_application_id
  
  after_create :create_notification
  
  def create_notification
    Notification.create(:subject => self, :verb => 'created')
  end
  
  # wrap remote_imge to always add our local FFlickr... FIXME
  def remote_image
    return nil if self.attributes['remote_image'].blank?
    "http://fffff.at/tempt1/photos/data/eyetags/#{self.attributes['remote_image'].gsub('gml','png')}"
  end
  
  # if we have a remote image (for Tempt) use that...
  def thumbnail_image(size = :medium)
    if !remote_image.blank?
      return "http://fffff.at/tempt1/photos/data/eyetags/thumb/#{self.attributes['remote_image'].gsub('gml','png')}"
    else
      return self.image(size)
    end
  end
  
  # GML document as a Nokogiri object...
  def gml_document
    parse_gml_document
  end
  
  # Wrap to_json so the .gml string gets converted to a hash, then to json
  # 
  # TODO we could use a 'GML' object type!
  def to_json(options = {})
    self.gml = Hash.from_xml(self.gml)
    self.gml = self.gml['gml'] if self.gml['gml'] # drop any duplicate parent-level <gml>'s
    super(options)
  end

  # Possibly strip all empty attributes... not sure if serving blank or not serving is better
  # def to_xml(options = {})
  #   options[:except] ||= []
  #   options[:except] += self.attributes.select { |key,value| puts "#{key}"; value.blank? }
  #   super(options)
  # end

  # convert directly from the GML string to JSON
  def gml_to_json
    Hash.from_xml(self.gml).to_json
  end

  
  
  
  
  
protected

  def parse_gml_document
    return nil if self.gml.blank?
    @document ||= Nokogiri::XML(self.gml)
  end
    

  # extract some information from the GML
  # and insert our server signature
  def process_gml
    doc = parse_gml_document
    header = (doc/'header')
    if header.blank?
      STDERR.puts "No header in GML: #{self.gml}"
      return nil
    end
    
    attrs = {}
    attrs[:filename] = (header/'filename')[0].innerHTML rescue nil
    
    obj = (header/'client')[0] rescue nil
    attrs[:client] = (obj/'name').innerHTML rescue nil
    
    STDERR.puts "Tag.process_gml: #{attrs.inspect}"    
    self.application = attrs[:client] unless attrs[:client].blank?
    self.remote_image = attrs[:filename] unless attrs[:filename].blank?

    return attrs   
  rescue
    STDERR.puts "Tag.process_gml error: #{$!}"
  end
    
  # verify the specified secret, or else say unknown
  def process_app_id
    # TODO
  end
    
  # simpe hack to check secret/appname for if this is tempt...
  # if so, save it to his User for him
  def validate_tempt
    # if secret 
    if self.application =~ /eyeSaver/ #WEAK as hell son.
      user = User.find_by_login('tempt1')
      self.user_id = user.id
    end    
  end
  
  
end
