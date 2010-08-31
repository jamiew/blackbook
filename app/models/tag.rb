class Tag < ActiveRecord::Base

  # Blacklisted attributes, do not show in the API
  # TODO convert to a whitelisted approach...
  HIDDEN_ATTRIBUTES = [:ip, :user_id, :remote_secret, :cached_tag_list, :uniquekey_hash]

  belongs_to :user
  has_one :gml_object, :class_name => 'GMLObject' # used to store the actual data, nice & gzipped
  has_many :comments, :as => :commentable, :order => 'created_at DESC'
  has_many :likes

  # validates_presence_of :user_id, :on => :create, :message => "can't be blank"
  validates_associated :user, :on => :create

  # before_save :process_gml
  # before_save :process_app_id
  before_create :detect_tempt_one
  before_save   :copy_gml_temp_to_gml_object
  before_create :build_gml_object
  after_create  :save_gml_object
  after_create  :create_notification

  # Caching related
  # after_save    :expire_gml_hash_cache #<-- handling in the Controller
  # after_destroy :delete_gml_hash_cache

  # Security: protect from mass assignment
  attr_protected :user_id

  # Scopes -- mostly related to presence of uniquekeys
  named_scope :from_device, {:conditions => 'gml_uniquekey IS NOT NULL'}
  named_scope :claimed, {:conditions => 'gml_uniquekey IS NOT NULL AND user_id IS NOT NULL'}
  named_scope :unclaimed, {:conditions => 'gml_uniquekey IS NOT NULL AND user_id IS NULL' }
  named_scope :by_uniquekey, lambda { |key| {:conditions => ['gml_uniquekey = ?',key]} }

  # validates_attachment_presence :image
  has_attached_file :image,
    :default_style => :medium,
    :default_url => "/images/defaults/tag_:style.jpg",
    # :path => ":rails_root/public/system/:class/:attachment/:id_partition/:basename_:style.:extension"
    :styles => { :large => '600x600>', :medium => "300x300>", :small => '100x100#', :tiny => "32x32#" }

  # Placeholders for assigning data from forms
  attr_accessor :gml_file
  attr_accessor :existing_application_id
  attr_accessor :validation_results


  # wrap remote_imge to always add our local FFlickr...
  # this secures tempt's tags on the site
  def self.remote_image_prefix
    "http://fffff.at/tempt1/photos/data/eyetags"
  end

  def remote_image
    return nil if self.attributes['remote_image'].blank?
    "http://fffff.at/tempt1/photos/data/eyetags/#{self.attributes['remote_image'].gsub('gml','png')}"
  end

  # if we have a remote image (for Tempt) use that...
  def thumbnail_image(size = :medium)
    if !remote_image.blank?
      return "http://fffff.at/tempt1/photos/data/eyetags/thumb/#{self.attributes['remote_image'].gsub('gml','png')}"
    # elsif RAILS_ENV == 'development' && !File.exist?(self.image_path(size)) #don't do image 404s in development
    #   return "/images/defaults/tag_#{size.to_s}.jpg"
    else
      return self.image(size)
    end
  end

  # Check to see if this data is from an iPhone, which means we'll need to rotate
  def from_iphone?
    app_matcher = /(DustTag|Dust Tag|Fat Tag|Katsu)/
    test = !(self.gml_application =~ app_matcher || self.application =~ app_matcher).blank?
    # puts "from_iphone?(#{self.gml_application} || #{self.application}) = #{test}"
    return test
  end

  # Wrapper accessors for the GML data, now stored in another object
  def gml(opts = {})
    return rotated_gml if opts[:iphone_rotate].to_s == '1' #handoff for backwards compt; DEPRECATEME
    @memoized_gml ||= gml_object && gml_object.data || @gml_temp || self.attributes['gml'] || ''
    return @memoized_gml
  end

  # hack around todd's player not rotating, swap x/y for 90 deg turn for iphone
  def rotated_gml
    Rails.cache.fetch(rotated_gml_cache_key) { rotate_gml }
  end

  # Proxy; will be processed on save
  def gml=(fresh)
    @gml_temp = fresh
  end

  # the GML data (String) as a Hash (w/ caching, conversion is an expensive operation)
  def gml_hash
    @gml_hash ||= Rails.cache.read(gml_hash_cache_key)
    if @gml_hash.blank?
      @gml_hash = convert_gml_to_hash
      Rails.cache.write(gml_hash_cache_key, @gml_hash)
    end
    return @gml_hash
  end

  # Wrap to_json so the .gml string gets converted to a hash, then to json
  # We're reimplementing Rails' to_json because we can't do :methods => {:gml_hash=>:gml},
  # and end up with an attribute called 'gml_hash' which doesn't work
  def to_json(options = {})
    hash = Serializer.new(self, options).serializable_record
    hash[:gml] = self.gml_hash && self.gml_hash['gml'] || {}
    hash.reject! { |k,v| v.blank? }
    ActiveSupport::JSON.encode(hash)
  end

  # Also hide what we'd like, and strip empty records (for now)
  def to_xml(options = {})
    options[:except] ||= []
    options[:except] += self.attributes.select { |key,value| value.blank? }
    super(options)
  end

  # GML as a Nokogiri object...
  def gml_document
    return nil if self.gml.blank?
    @document ||= Nokogiri::XML(self.gml)
  end
  alias :document :gml_document # Can't decide on the name; how much gml_ prefixing do we want?

  # Read the important bits of the GML -- also called by the save_header :before_save hook
  def gml_header
    # doc = self.class.read_gml_header(self.gml)
    doc = gml_document

    if doc.nil? || (doc/'header').nil?
      logger.error "NIL OR NO HEADER DOC"
      return {}
    end

    attrs = {}
    attrs[:filename] = (doc/'header'/'filename')[0].text rescue nil

    # whitelist approach -- explicitly name things
    client = (doc/'header'/'client')[0] rescue nil
    attrs[:gml_application] = (client/'name').text rescue nil
    attrs[:gml_username] = (client/'username').text rescue nil
    attrs[:gml_keywords] = (client/'keywords').text rescue nil
    attrs[:gml_uniquekey] = (client/'uniqueKey').text rescue nil

    # Non-gml_ prefixed fields...
    attrs[:location] = (client/'location').text rescue nil # this could also be in <drawing>

    # encode the uniquekey with SHA-1 immediately
    # FIXME this slows this method down significantly -- denormalize whole hash to the model on save...?
    attrs[:gml_uniquekey_hash] = self.class.hash_uniquekey(attrs[:gml_uniquekey]) unless attrs[:gml_uniquekey].blank?

    return attrs
  end

  # def self.read_gml_header(gml)
  #   # DRY with Tag.new.gml_document
  #   doc = Nokogiri::XML(self.gml)
  # end

  # TODO inject 000000book infos into this GML...

  # Dump some chars from the uniquekey as a Secret User Codename
  def secret_username
    return nil if gml_uniquekey_hash.blank?
    "anon-"+gml_uniquekey_hash[-5..-1]
  end

  # Sexify the app name (this could be a helper)
  # TODO: link
  def sexy_app_name
    # puts "gml_application=#{gml_application.inspect} application=#{application.inspect}"
    (!application.blank? && application) || (!gml_application.blank? && gml_application) || ''
  end

  # Favorites-related -- TODO this should be elsewhere/via named_scopes
  def favorited_by?(user)
    Favorite.count(:conditions => ['object_id = ? AND object_type = ? AND user_id = ?', self.id, self.class.to_s, user.id]) > 0
  end

  # Transforms (cached)
  def gml_hash_cache_key
    "tag/#{id}/gml_hash"
  end

  def convert_gml_to_hash
    return {} if self.gml.blank?
    Hash.from_xml(gml_document.to_xml)
  rescue
    logger.error "ERROR: could not parse GML for Tag #{self.id} into a hash: #{$!}"
    return {}
  end

  def rotated_gml_cache_key
    "tag/#{id}/rotated_gml"
  end

  def rotate_gml
    doc = gml_document
    strokes = (doc/'drawing'/'stroke')
    strokes.each { |stroke|
      (stroke/'pt').each { |pt|
        _x = (pt/'x')[0].content
        (pt/'x')[0].content = (pt/'y')[0].content
        (pt/'y')[0].content = (1.0 - _x.to_f).to_s
      }
    }
    # response gets cached so convert to string right away
    return doc.to_s
  rescue
    logger.error "ERROR: could not rotate GML for #{self.id}: #{$!}"
    return nil
  end

  # Parse and build errors & warnings
  # Not actually used as a validation, but
  def validate_gml
    doc = gml_document
    errors, warnings, recommendations = [], [], []

    # TODO use nested tags -- e.g. stroke/pt/t rather than just t
    errors << check_for_tag('stroke', "No <stroke> tags - at least 1 stroke required")
    errors << check_for_tag('pt', "No <pt> tags - GML requires at least 1 point. This isn't 'EmptyML'")

    warnings << check_for_tag('time', "No <time> tags in your points! Time data makes things so much more interesting")
    warnings << check_for_tag('environment', "No <environment> tag")
    warnings << check_for_tag('up', "No <up> tag in your <environment> - is this horizontal or landscape?!")
    warnings << check_for_tag('screenBounds', "No <screenBounds> tag in your <environment> - otherwise apps might draw it in the wrong aspect ratio")

    # Suggest newlines & indenting!
    recommendations << "You don't have any newlines. Proper formatting makes your GML nice & human-readable" unless doc.to_s =~ /\n/
    recommendations << "You don't have any tabs. Indenting is the bomb yo" unless doc.to_s =~ /\t/ || doc.to_s =~ /  / # assume 2 spaces = 1 tab

  rescue
    errors << "Error parsing GML (malformed XML?): #{$!.class} - #{$!}"
  ensure
    self.validation_results = {:errors => errors.compact, :warnings => warnings.compact, :recommendations => recommendations.compact}
    self.validation_results.reject! { |key,value| value.blank? }
    logger.info "GML Validation Results..."
    logger.info self.validation_results.inspect
    return validation_results
  end


protected

  def create_notification
    Notification.create(:subject => self, :verb => 'created', :user => self.user)
  end

  # before_create hook to copy over our temp data & then read our GML
  def build_gml_object
    # STDERR.puts "Tag #{self.id}, creating GML object... current gml attribute is #{self.attributes['gml'].length rescue nil} bytes"
    obj = GMLObject.new
    obj.data = @gml_temp || self.attributes['gml'] #attr_protected
    self.gml_object = obj
    process_gml
    save_header
    find_paired_user
  end

  # after_create hook to finalize the GMLObject
  def save_gml_object
    self.gml_object.tag = self
    self.gml_object.save!
  end

  def copy_gml_temp_to_gml_object
    return if @gml_temp.blank? || gml_object.nil?
    gml_object.data = @gml_temp
    gml_object.save! if gml_object.data_changed?
  end

  # Parse & assign variables from the GML header
  # only save attributes we actually have, but allow displaying everything we can parse
  def save_header
    return if gml_header.blank?
    attrs = gml_header.select { |k,v| self.send("#{k}=", v) if self.respond_to?(k) && !v.blank?; [k,v] }.to_hash
    # puts "Tag.save_header: #{attrs.inspect}"
    return attrs
  end

  # assign a user if there's a paired iPhone uniquekey
  def find_paired_user
    logger.debug "Tag.find_paired_user: self.gml_uniquekey=#{self.gml_uniquekey}"
    return if self.gml_uniquekey.blank?
    user = User.find_by_iphone_uniquekey(self.gml_uniquekey) rescue nil
    return if user.nil?
    logger.info "Pairing with user=#{user.login.inspect}"
    self.user = user
  end

  # extract some information from the GML
  # and insert our server signature
  # FIXME duplicating some stuff from save_header
  def process_gml
    doc = gml_document
    return if doc.nil?

    header = (doc/'header')
    if header.blank?
      logger.error "Tag.process_gml: no header found in GML"
      # TODO raise exception
      return nil
    end

    attrs = {}
    attrs[:filename] = (header/'filename')[0].inner_html rescue nil

    obj = (header/'client')[0] rescue nil
    attrs[:client] = (obj/'name').inner_html rescue nil

    # STDERR.puts "Tag.process_gml: #{attrs.inspect}"
    # self.application = attrs[:client] unless attrs[:client].blank?
    self.remote_image = attrs[:filename] unless attrs[:filename].blank?

    return attrs
  rescue
    logger.error "Tag.process_gml error: #{$!}"
  end

  # simpe hack to check secret/appname for if this is tempt...
  # if so, save it to his User for him
  def detect_tempt_one
    if self.application =~ /eyeSaver/ # weak
      user = User.find_by_login('tempt1')
      self.user_id = user.id
    end
  end

  def self.hash_uniquekey(string)
    Digest::SHA1.hexdigest(string)
  end

  def check_for_tag(tag, message)
    @tag_doc ||= gml_document
    logger.info "check_for_tag(#{tag.inspect}, #{message.inspect})"
    if (@tag_doc/tag).blank?
      return message
    else
      return nil
    end
  end

end
