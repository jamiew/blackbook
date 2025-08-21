class Tag < ActiveRecord::Base

  # Blacklisted attributes, do not show in the API
  # TODO convert to a whitelisted approach...
  HIDDEN_ATTRIBUTES = [:ip, :user_id, :remote_secret, :cached_tag_list, :uniquekey_hash]

  belongs_to :user
  has_many :comments, as: :commentable
  has_many :likes

  # delegate :data, to: :gml_object

  # validates_presence_of :user_id, on: :create, message: "can't be blank"
  validates_associated :user, on: :create

  # before_save :process_gml
  # before_save :process_app_id
  before_save   :copy_gml_temp_to_gml_object
  before_save   :check_for_gml_object
  before_create :build_gml_object
  after_create  :save_gml_object
  after_create  :create_notification


  scope :from_device, -> { where('gml_uniquekey IS NOT NULL') }
  scope :claimed, -> { where('gml_uniquekey IS NOT NULL AND user_id IS NOT NULL') }
  scope :unclaimed, -> { where('gml_uniquekey IS NOT NULL AND user_id IS NULL') }

  # validates_attachment_presence :image
  # validates_attachment :image, content_type: { content_type: ["image/jpg", "image/jpeg", "image/png", "image/gif"] }
  do_not_validate_attachment_file_type :image
  has_attached_file :image,
    default_style: :medium,
    default_url: "/images/defaults/tag_:style.jpg",
    url: "/system/:attachment/:id_partition/:style/:basename.:extension",
    path: ":rails_root/public/system/:attachment/:id_partition/:style/:basename.:extension",
    styles: { large: '600x600>', medium: "300x300>", small: '100x100#', tiny: "32x32#" }

  # Placeholders for assigning data from forms
  attr_accessor :gml_file
  attr_accessor :_gml_object
  attr_accessor :existing_application_id
  attr_accessor :validation_results

  # Some interesting test cases
  EXAMPLES = {
    valid_gml: 3001,
    rotated: 3000,
    bad_binary_data: 5198,
    # empty: TODO
    # invalid_gml: TODO
    # tempt1_eyesaver: TODO
    # TODO one from each iPhone app
  }

  def gml_object
    self._gml_object ||= GmlObject.new(tag: self)
    self._gml_object
  end

  def gml_object=(obj)
    # Rails.logger.debug "Tag #{id}: gml_object="
    self._gml_object = obj
  end

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
    # elsif Rails.env == 'development' && !File.exist?(self.image_path(size)) #don't do image 404s in development
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

  # Smart wrapper for the GML data, actually stored in `GmlObject.data`
  def gml(opts = {})
    # Rails.logger.debug "Tag #{id}: gml"
    return nil if gml_object.blank? || gml_object.data.blank?
    return rotated_gml if opts[:iphone_rotate].to_s == '1' # handoff for backwards compt; DEPRECATEME
    @memoized_gml ||= gml_object && gml_object.data || @gml_temp
    return @memoized_gml
  end

  def data
    # Rails.logger.debug "Tag #{id.inspect}: data"
    # rotate_gml
    gml
  end

  def data=(arg)
    # Rails.logger.debug "Tag #{id.inspect}: data="
    # raise "why are you doing tag.data="
    @gml_temp = arg
    gml_object.data = arg
  end

  # hack around todd's player not rotating, swap x/y for 90 deg turn for iphone
  def rotated_gml
    # Rails.logger.debug "Tag #{id}: rotated_gml (cached)"
    Rails.cache.fetch(rotated_gml_cache_key) { rotate_gml.to_s }
  end

  # Proxy; will be processed on save
  def gml=(fresh)
    # FIXME wtf is going on
    if fresh.kind_of?(ActionDispatch::Http::UploadedFile)
      Rails.logger.warn "Warning, reading data from ActionDispatch::Http::UploadedFile"
      fresh = fresh.read
    end

    # Rails.logger.debug "Tag #{id}: gml= (#{fresh[0..100]}"
    @gml_temp = fresh
  end

  # the GML data (String) as a Hash (w/ caching, conversion is an expensive operation)
  def gml_hash
    # Rails.logger.debug "Tag #{id}: gml_hash"
    @gml_hash ||= Rails.cache.read(gml_hash_cache_key)
    if @gml_hash.blank?
      @gml_hash = convert_gml_to_hash
      Rails.cache.write(gml_hash_cache_key, @gml_hash)
    end
    return @gml_hash
  end

  # Override so we can add gml: :gml_hash
  # Arguably could just be using :methods but we always want this
  def as_json(_opts = {})
    # Rails.logger.debug "Tag #{id}: as_json"
    hash = super(_opts)
    hash.reject! {|k,v| v.blank? }
    hash[:gml] = self.gml_hash && self.gml_hash['gml']
    hash[:gml] ||= self.gml_hash && self.gml_hash['GML']
    hash[:gml] ||= {}
    hash
  end

  # Also hide what we'd like, and strip empty records (for now)
  def to_xml(options = {})
    # Rails.logger.debug "Tag #{id}: to_xml"
    options[:except] ||= []
    options[:except] += self.attributes.map {|k,v| k if v.blank? }.compact
    super(options)
  end

  # GML as a Nokogiri object...
  def gml_document
    # Rails.logger.debug "Tag #{id}: gml_document"
    return nil if self.gml.blank?
    @document ||= Nokogiri::XML(self.gml)
  rescue ArgumentError
    Rails.logger.error "Error parsing GML document for id=#{self.id}"
    nil
  end

  # Read the important bits of the GML -- also called by the save_header :before_save hook
  def gml_header
    # Rails.logger.debug "Tag #{id}: gml_header"
    # doc = self.class.read_gml_header(self.gml)
    doc = gml_document

    if doc.nil? || (doc/'header').nil?
      Rails.logger.error "Tag#gml_header: NIL OR NO HEADER DOC"
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
    Favorite.where('object_id = ? AND object_type = ? AND user_id = ?', self.id, self.class.to_s, user.id).count > 0
  end

  # Transforms (cached)
  def gml_hash_cache_key
    "tag/#{id}/gml_hash"
  end

  def convert_gml_to_hash
    # Rails.logger.debug "Tag #{id}: convert_gml_to_hash"
    return {} if self.gml.blank?
    Hash.from_xml(gml_document.to_xml)
  rescue
    Rails.logger.error "ERROR: could not parse GML for Tag #{self.id} into a hash: #{$!}"
    return {}
  end

  def rotated_gml_cache_key
    "tag/#{id}/rotated_gml"
  end

  def rotate_gml
    # Rails.logger.debug "Tag #{id}: rotate_gml"
    doc = gml_document
    strokes = (doc/'drawing'/'stroke')
    strokes.each { |stroke|
      (stroke/'pt').each { |pt|
        _x = (pt/'x')[0].content
        (pt/'x')[0].content = (pt/'y')[0].content
        (pt/'y')[0].content = (1.0 - _x.to_f).to_s
      }
    }
    doc
  rescue
    Rails.logger.error "ERROR: could not rotate GML for #{self.id}: #{$!}"
    return nil
  end

  # Parse and build errors & warnings
  # Not actually used as a validation, but
  def validate_gml
    # Rails.logger.debug "Tag #{id}: validate_gml"
    doc = gml_document
    errors, warnings, recommendations = [], [], []

    # TODO use nested tags -- e.g. stroke/pt/t rather than just t
    errors << check_for_tag('stroke', "No <stroke> tags - at least 1 stroke required")
    errors << check_for_tag('pt', "No <pt> tags - GML requires at least 1 point. This isn't 'EmptyML'")
    # TODO iterate through each pt to ensure each has x/y's -- not just any x/y
    errors << check_for_tag('x', "Missing <x> tags inside your <pt>'s")
    errors << check_for_tag('y', "Missing <y> tags inside your <pt>'s")

    # TODO parse & verify all pt values are between 0 and 1.0

    warnings << check_for_tag('time', "No <time> tags in your <pt> tags! Capturing time data makes things much more interesting.")
    warnings << check_for_tag('client', "No <client> tag - provide some info about your app!")
    warnings << check_for_tag('environment', "No <environment> tag")
    warnings << check_for_tag('up', "No <up> tag in your <environment> - is this horizontal or landscape?!")
    warnings << check_for_tag('screenBounds', "No <screenBounds> tag in your <environment> - otherwise apps might draw it in the wrong aspect ratio")
    # Offset? Rotation? z coords? could be a 'protips' section...
    # Time? Maybe just recommendation?

    recommendations << check_for_tag('uniqueKey', "No <uniqueKey> tag - includign a unique device ID of some kind lets users pair their 000000book accounts with your app, e.g. iPhone uuid, MAC address, etc")
    recommendations << "You don't have any newlines. Proper formatting makes your GML nice & human-readable" unless doc.to_s =~ /\n/
    recommendations << "You don't have any tabs. Indenting is the bomb yo" unless doc.to_s =~ /\t/ || doc.to_s =~ /  / # assume 2 spaces = 1 tab
    # Geo information?

  rescue
    errors << "Error parsing GML (malformed XML?)"+(Rails.env == 'development' ? ": #{$!.class} - #{$!}" : '')

  ensure
    self.validation_results = ActiveSupport::OrderedHash.new
    self.validation_results[:errors] = errors.compact unless errors.blank?
    self.validation_results[:warnings] = warnings.compact unless warnings.blank?
    self.validation_results[:recommendations] = recommendations.compact unless recommendations.blank?

    Rails.logger.debug "GML Validation Results..."
    Rails.logger.debug self.validation_results.inspect
    return validation_results
  end


protected

  def create_notification
    Notification.create(subject: self, verb: 'created', user: self.user)
  end

  # before_create hook to copy over our temp data & then read our GML /
  def build_gml_object
    Rails.logger.debug "Tag #{self.id}: build_gml_object ... current gml attribute is #{self.attributes['gml'].length rescue nil} bytes"
    obj = GmlObject.new(tag_id: self.id) # tag_id nil if we're unsaved, but not if it's old or being fixed
    obj.data = @gml_temp || self.attributes['gml']
    self.gml_object = obj
    process_gml
    save_header
    find_paired_user
  end

  # after_create hook to finalize the GmlObject
  def save_gml_object
    # Rails.logger.debug "Tag #{id}: save_gml_object..."
    self.gml_object.tag_id ||= id # FIXME? fail-safe for if you build object pre-save, when tag has no id
    self.gml_object.save!
  end

  def copy_gml_temp_to_gml_object
    # Rails.logger.debug "Tag #{id}: copy_gml_temp_to_gml_object..."
    return if gml_object.nil? || @gml_temp.blank?
    gml_object.data = @gml_temp
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
    Rails.logger.debug "Tag.find_paired_user: self.gml_uniquekey=#{self.gml_uniquekey}"
    return if self.gml_uniquekey.blank?
    user = User.find_by_iphone_uniquekey(self.gml_uniquekey)
    return if user.nil?
    Rails.logger.debug "Pairing with user=#{user.login.inspect}"
    self.user = user
  end

  # extract some information from the GML
  # and insert our server signature
  # FIXME duplicating some stuff from save_header
  def process_gml
    Rails.logger.debug "Tag #{id}: process_gml"
    doc = gml_document
    return if doc.nil?

    header = (doc/'header')
    if header.blank?
      Rails.logger.error "Tag.process_gml: no header found in GML"
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
    Rails.logger.error "Tag.process_gml error: #{$!}"
    return nil
  end

  def self.hash_uniquekey(string)
    Digest::SHA1.hexdigest(string)
  end

  def check_for_tag(tag, message)
    @tag_doc ||= gml_document
    if (@tag_doc/tag).blank?
      return message
    else
      return nil
    end
  end

  def check_for_gml_object
    if self.gml_object.nil?
      Rails.logger.error "ERROR: Missing gml_object for Tag #{self.id}"
    elsif !self.gml_object.valid?
      # Rails.logger.warn "Warning: Invalid gml_object for Tag #{self.id}"
    end
  end

end
