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
  HIDDEN_ATTRIBUTES = [:ip, :user_id, :remote_secret, :cached_tag_list]

  # is_taggable :tags
  #TODO: cache_money indexes
  
  belongs_to :user
  has_one :gml_object, :class_name => 'GMLObject' #used to store the actual data, nice & gzipped
  has_many :comments, :as => :commentable
  has_many :likes
  
  validates_associated :user, :on => :create
  
  before_save :process_gml  
  before_create :validate_tempt
  # before_save :process_app_id
  before_save :save_header
  
  # Security: protect from mass assignment
  attr_protected :user_id
    
  has_attached_file :image, 
    :default_style => :medium,
    :default_url => "/images/defaults/tag_:style.jpg",
    :styles => { :large => '600x600>', :medium => "300x300>", :small => '100x100#', :tiny => "32x32#" }
  # validates_attachment_presence :image
    
  # Placeholders for assigning data from forms  
  attr_accessor :gml_file, :existing_application_id
  
  after_create :create_gml_object
  after_create :create_notification

  #Hackish; need a "filler" obj while we're building... don't have an ID before create.
  # and don't wanna save it to ourselves before committing
  before_save :copy_gml_temp_to_gml_object  
  
  
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
  
  # Wrapper accessors for the GML data, now stored in another object
  def gml
    gml_object && gml_object.data || self.attributes['gml'] || ''
  end
  
  # Hacks for GML copying...
  def gml=(fresh)  
    # gml_object && gml_object.data = fresh
    @gml_temp = fresh
  end
  
  def copy_gml_temp_to_gml_object
    return if @gml_temp.blank? || gml_object.nil?
    gml_object.data = @gml_temp
    gml_object.save! if gml_object.data_changed? #we might be double-saving...
  end
  
  # Wrap to_json so the .gml string gets converted to a hash, then to json
  #TODO: we could use a 'GML' object type! it should have its own table -- all this stuff is quite slow...
  #TODO: this is quite an expensive operation :(
  def to_json(options = {})
    self.gml = Hash.from_xml(self.gml)
    self.gml = self.gml['gml'] if self.gml['gml'] # drop any duplicate parent-level <gml>'s
    super(options)
  end

  # convert directly from the GML string to JSON
  def gml_to_json
    Hash.from_xml(self.gml).to_json
  end

  # Possibly strip all empty attributes... not sure if serving blank or not serving is better
  # def to_xml(options = {})
  #   options[:except] ||= []
  #   options[:except] += self.attributes.select { |key,value| puts "#{key}"; value.blank? }
  #   super(options)
  # end

  # GML as a Nokogiri object...
  def gml_document
    return nil if self.gml.blank?
    @document ||= Nokogiri::XML(self.gml)
  end
  alias :document :gml_document # Can't decide on the name; how much gml_ prefixing do we want?
  
  # Read the important bits of the GML -- this is also used
  # by the before_save processing method to add
  def gml_header
    # doc = self.class.read_gml_header(self.gml)
    doc = gml_document
    return {} if doc.nil? || (doc/'header').nil?

    attrs = {}
    attrs[:filename] = (doc/'header'/'filename')[0].text rescue nil    
    
    # whitelist approach, explicitly name things
    client = (doc/'header'/'client')[0] rescue nil
    attrs[:gml_application] = (client/'name').text rescue nil
    attrs[:gml_username] = (client/'username').text rescue nil
    attrs[:gml_keywords] = (client/'keywords').text rescue nil
    attrs[:gml_uniquekey] = (client/'uniqueKey').text rescue nil
    
    # encode the uniquekey with SHA-1 immediately
    attrs[:gml_uniquekey_hash] = Digest::SHA1.hexdigest(attrs[:gml_uniquekey]) unless attrs[:gml_uniquekey].blank?    
    
    return attrs
  end
  
  def save_header
    # only save attributes we actually have please, but allow displaying everything we can parse
    # this could be confusing later -- document well or refactor...
    return if gml_header.blank?
    attrs = gml_header.select { |k,v| self.send("#{k}=", v) if self.respond_to?(k); [k,v] }.to_hash
    puts "Tag.save_header: #{attrs.inspect}"
  end
  
  # def self.read_gml_header(gml)
  #   # DRY with Tag.new.gml_document
  #   doc = Nokogiri::XML(self.gml)
  # end
  
  #TODO: inject 000000book infos into this GML...
  
  # Dump some chars from the uniquekey as a Secret User Codename
  def user_secret_name
    return if gml_uniquekey_hash.nil?
    "anon-"+gml_uniquekey_hash[-5..-1]
  end
  
  
  
protected    

  def create_notification
    Notification.create(:subject => self, :verb => 'created')
  end
  
  # make sure we have a gml
  def create_gml_object
    STDERR.puts "Tag #{self.id}, creating GML object... current gml attribute is #{self.attributes['gml'].length rescue nil} bytes"
    obj = GMLObject.new(:tag => self)
    obj.data = @gml_temp || self.attributes['gml'] || '' # attr_protected
    obj.save!
    self.gml_object = obj # Is this automatically assigned to us without reloading? Making sure...
  end



  # extract some information from the GML
  # and insert our server signature
  def process_gml
    doc = gml_document
    header = (doc/'header')
    if header.blank?
      STDERR.puts "No header in GML: #{self.gml}"
      return nil
    end
  
    attrs = {}
    attrs[:filename] = (header/'filename')[0].inner_html rescue nil
  
    obj = (header/'client')[0] rescue nil
    attrs[:client] = (obj/'name').inner_html rescue nil
  
    STDERR.puts "Tag.process_gml: #{attrs.inspect}"    
    self.application = attrs[:client] unless attrs[:client].blank?
    self.remote_image = attrs[:filename] unless attrs[:filename].blank?

    return attrs   
  rescue
    STDERR.puts "Tag.process_gml error: #{$!}"
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
