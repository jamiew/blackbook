require 'English'
class Tag < ApplicationRecord
  # Attributes the API publishes, in schema order so the XML element order does
  # not move.
  #
  # An allowlist, because the blocklist this replaces failed twice over. It
  # named `uniquekey_hash`, a column that does not exist, and never named the
  # raw `gml_uniquekey` at all, so both went out in .json. Worse, it held
  # symbols while #to_xml matched them against string attribute keys, so .xml
  # excluded nothing and served `ip`, `user_id` and `remote_secret` to anyone
  # who asked. app/views/tags/show.html.haml calls the uniquekey pair "Secret
  # Fields" and shows them to the owner and admins only; anyone holding a
  # device's uniqueKey can have their uploads attributed to that device's
  # owner. See #find_paired_user.
  #
  # Adding a column no longer publishes it. That is the point.
  PUBLIC_ATTRIBUTES = %w[
    id application author comment_count created_at description
    gml_application gml_keywords gml_username gml_version
    image_content_type image_file_name image_file_size image_updated_at
    likes_count location remote_image slug title updated_at uuid
  ].freeze

  # Everything else. Only here so that adding a column without deciding which
  # list it belongs in fails a spec instead of quietly appearing in the API.
  # See spec/models/tag_spec.rb.
  #
  # ip is the uploader's address. user_id and cached_tag_list are internal.
  # remote_secret is vestigial: accepted from ?secret= and never read back.
  # The gml_uniquekey pair is a device credential -- see UNIQUEKEY_ELEMENT --
  # and secret_username is derived from the hash.
  PRIVATE_ATTRIBUTES = %w[
    ip user_id cached_tag_list remote_secret gml_uniquekey gml_uniquekey_hash
  ].freeze

  belongs_to :user, optional: true
  has_many :favorites, as: :object

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

  scope :from_device, -> { where.not(gml_uniquekey: nil) }
  scope :claimed, -> { where('gml_uniquekey IS NOT NULL AND user_id IS NOT NULL') }
  scope :unclaimed, -> { where('gml_uniquekey IS NOT NULL AND user_id IS NULL') }
  # Seek to a random primary key rather than ORDER BY RAND(), which sorted all
  # 76,000 rows on every hit and made the cheapest-looking public endpoint the
  # most expensive one we serve. This is two index lookups and a PK seek.
  #
  # Deleted ids leave gaps, so a row just after a gap comes up slightly more
  # often. That does not matter for "show me something".
  def self.random
    lowest = minimum(:id)
    highest = maximum(:id)
    return nil if lowest.nil?

    where(id: rand(lowest..highest)..).order(:id).first || order(:id).first
  end

  # Tag images arrive from GMLImageRenderer rather than a user upload, and were
  # deliberately exempt from filetype validation under Paperclip too.
  # Variant names and geometry match the Paperclip styles they replace, so a
  # backfilled image renders identically. resize_to_limit is Paperclip's ">"
  # (shrink only, keep aspect); resize_to_fill is its "#" (crop to exact size).
  has_one_attached :image do |attachable|
    attachable.variant :large,  resize_to_limit: [600, 600]
    attachable.variant :medium, resize_to_limit: [300, 300]
    attachable.variant :small,  resize_to_fill:  [100, 100]
    attachable.variant :tiny,   resize_to_fill:  [32, 32]
  end

  def default_image_url(style) = "/images/defaults/tag_#{style}.jpg"

  # Placeholders for assigning data from forms
  attr_accessor :gml_file
  attr_accessor :_gml_object, :existing_application_id, :validation_results

  # Some interesting test cases
  EXAMPLES = {
    valid_gml: 3001,
    rotated: 3000,
    bad_binary_data: 5198
    # empty: TODO
    # invalid_gml: TODO
    # tempt1_eyesaver: TODO
    # TODO one from each iPhone app
  }.freeze

  def gml_object
    self._gml_object ||= GmlObject.new(tag: self)
    _gml_object
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
    return nil if attributes['remote_image'].blank?

    "http://fffff.at/tempt1/photos/data/eyetags/#{attributes['remote_image'].gsub('gml', 'png')}"
  end

  # Tempt's tags are hosted elsewhere and have no attachment of their own.
  # Returns nil when this tag is not one of those, and the caller falls back to
  # the attachment. See ApplicationHelper#tag_thumbnail_url.
  def remote_thumbnail_url
    return nil if remote_image.blank?

    "http://fffff.at/tempt1/photos/data/eyetags/thumb/#{attributes['remote_image'].gsub('gml', 'png')}"
  end

  # Check to see if this data is from an iPhone, which means we'll need to rotate
  def from_iphone?
    app_matcher = /(DustTag|Dust Tag|Fat Tag|Katsu)/
    (gml_application =~ app_matcher || application =~ app_matcher).present?
    # puts "from_iphone?(#{self.gml_application} || #{self.application}) = #{test}"
  end

  # The device uniqueKey is a credential, not metadata: anyone holding one can
  # have their uploads attributed to that device's owner (see #find_paired_user).
  # It must never leave the server in any format.
  #
  # Stripped from the served string rather than from the parsed document,
  # because a Nokogiri round-trip would reformat every .gml download.
  UNIQUEKEY_ELEMENT = %r{<uniqueKey>.*?</uniqueKey>}m

  # What #gml is allowed to become once it leaves the building. Everything that
  # serves GML goes through here; #gml itself stays raw because the upload path
  # reads the uniqueKey out of it to do the pairing.
  def public_gml(opts = {})
    gml(opts)&.gsub(UNIQUEKEY_ELEMENT, '')
  end

  # Smart wrapper for the GML data, actually stored in `GmlObject.data`
  def gml(opts = {})
    # Rails.logger.debug "Tag #{id}: gml"
    return nil if gml_object.blank? || gml_object.data.blank?
    return rotated_gml if opts[:iphone_rotate].to_s == '1' # handoff for backwards compt; DEPRECATEME

    @memoized_gml ||= gml_object&.data || @gml_temp
    @memoized_gml
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

  # HACK: around todd's player not rotating, swap x/y for 90 deg turn for iphone
  def rotated_gml
    # Rails.logger.debug "Tag #{id}: rotated_gml (cached)"
    Rails.cache.fetch(rotated_gml_cache_key) { rotate_gml.to_s }
  end

  # Proxy; will be processed on save
  def gml=(fresh)
    # FIXME: wtf is going on
    if fresh.is_a?(ActionDispatch::Http::UploadedFile)
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
    @gml_hash
  end

  # Compact payload for the canvas player: just the strokes, as flat
  # [x, y, time] triples. The full #as_json ships the whole XML-as-JSON tree,
  # which is several times larger and makes the player dig through a shape that
  # changes depending on how many strokes and points a tag happens to have.
  #
  # Timing is passed through untouched, including gaps and out-of-order stamps.
  # The player repairs it and reports what it had to do, so bad captures stay
  # visible instead of being silently smoothed over here.
  def player_data
    drawing = gml_hash.dig('gml', 'tag', 'drawing') || gml_hash.dig('GML', 'tag', 'drawing') || {}
    header  = gml_hash.dig('gml', 'tag', 'header') || gml_hash.dig('GML', 'tag', 'header') || {}
    env     = gml_hash.dig('gml', 'tag', 'environment') || gml_hash.dig('GML', 'tag', 'environment') || {}
    up      = env['up']

    strokes = Array.wrap(drawing['stroke']).filter_map do |stroke|
      next if stroke.blank?

      points = Array.wrap(stroke['pt']).filter_map do |pt|
        next if pt.blank?

        x = Float(pt['x'], exception: false)
        y = Float(pt['y'], exception: false)
        next if x.nil? || y.nil?

        [x.round(5), y.round(5), (Float(pt['time'], exception: false) || 0.0).round(4)]
      end
      next if points.empty?

      { color: stroke['color'], brush: Float(stroke['brush'] || stroke['stroke_size'], exception: false),
        drips: ActiveModel::Type::Boolean.new.cast(stroke['dripping']) || false, points: points }
    end

    { id: id,
      app: sexy_app_name.presence,
      screen: { x: Float(env.dig('screenBounds', 'x'), exception: false),
                y: Float(env.dig('screenBounds', 'y'), exception: false) },
      # Which way was up, so the client can settle rotation with the same
      # function the reference player uses. `rotate` stays for older clients.
      up: up.is_a?(Hash) ? { x: Float(up['x'], exception: false), y: Float(up['y'], exception: false) } : nil,
      rotate: landscape_capture?(env),
      client: header.dig('client', 'name'),
      strokes: strokes }
  end

  # player_data cut down for a grid of thumbnails: every Nth point, three
  # decimal places, no per-stroke styling. Thirty of these on a page come to
  # around 150KB, where thirty player_datas would be megabytes.
  PREVIEW_POINTS = 300

  def preview_data
    full = player_data
    total = full[:strokes].sum { |stroke| stroke[:points].size }
    step = [(total.to_f / PREVIEW_POINTS).ceil, 1].max

    strokes = full[:strokes].map do |stroke|
      points = stroke[:points]
      # The first point of every slice, and always the last, so each stroke
      # still ends where the hand did.
      kept = points.each_slice(step).map(&:first)
      kept << points.last unless kept.last.equal?(points.last)
      { points: kept.map { |x, y, t| [x.round(3), y.round(3), t.round(2)] } }
    end

    full.slice(:id, :app, :up, :rotate).merge(strokes: strokes)
  end

  # GML records which way was up when the tag was captured. An up vector along
  # +x means the device was held sideways and the points were written out
  # unrotated, so playback owes them a quarter turn.
  #
  # This is per capture, not per app: the same phone app appears with up=(1,0,0)
  # on old 480x320 captures and up=(0,1,0) on later ones. Matching on client
  # name -- which is what the old player did, and then rotated by 80 *radians*
  # rather than 90 degrees -- got both cases wrong.
  def landscape_capture?(env = nil)
    env ||= gml_hash.dig('gml', 'tag', 'environment') || gml_hash.dig('GML', 'tag', 'environment') || {}
    up = env['up'] || {}
    x = Float(up['x'], exception: false) || 0.0
    y = Float(up['y'], exception: false) || 0.0
    x.abs > y.abs
  end

  # Override so we can add gml: :gml_hash
  # Arguably could just be using :methods but we always want this
  #
  # `only:` is forced rather than left to the caller, so a controller cannot
  # forget it. In ActiveRecord `only` beats any `except` a caller passes.
  def as_json(opts = {})
    # Rails.logger.debug "Tag #{id}: as_json"
    hash = super(opts.merge(only: PUBLIC_ATTRIBUTES))
    hash.reject! { |_k, v| v.blank? }
    hash[:gml] = gml_hash && gml_hash['gml']
    hash[:gml] ||= gml_hash && gml_hash['GML']
    hash[:gml] ||= {}
    hash
  end

  # Publish only the allowlist, and strip empty values (for now).
  #
  # Options still pass through to Hash#to_xml because Array#to_xml calls this
  # for each element with :builder, :root and :skip_instruct set.
  def to_xml(options = {})
    # Rails.logger.debug "Tag #{id}: to_xml"
    attributes.slice(*PUBLIC_ATTRIBUTES).compact_blank.to_xml(options)
  end

  # GML as a Nokogiri object...
  def gml_document
    # Rails.logger.debug "Tag #{id}: gml_document"
    return nil if gml.blank?

    @document ||= Nokogiri::XML(gml)
  rescue ArgumentError
    Rails.logger.error "Error parsing GML document for id=#{id}"
    nil
  end

  # Read the important bits of the GML -- also called by the save_header :before_save hook
  def gml_header
    # Rails.logger.debug "Tag #{id}: gml_header"
    # doc = self.class.read_gml_header(self.gml)
    doc = gml_document

    if doc.nil? || (doc / 'header').nil?
      Rails.logger.error "Tag#gml_header: NIL OR NO HEADER DOC"
      return {}
    end

    attrs = {}
    attrs[:filename] = begin
      (doc / 'header' / 'filename')[0].text
    rescue StandardError
      nil
    end

    # whitelist approach -- explicitly name things
    client = begin
      (doc / 'header' / 'client')[0]
    rescue StandardError
      nil
    end
    attrs[:gml_application] = begin
      (client / 'name').text
    rescue StandardError
      nil
    end
    attrs[:gml_username] = begin
      (client / 'username').text
    rescue StandardError
      nil
    end
    attrs[:gml_keywords] = begin
      (client / 'keywords').text
    rescue StandardError
      nil
    end
    attrs[:gml_uniquekey] = begin
      (client / 'uniqueKey').text
    rescue StandardError
      nil
    end

    # Non-gml_ prefixed fields...
    attrs[:location] = begin
      (client / 'location').text
    rescue StandardError
      nil
    end

    # encode the uniquekey with SHA-1 immediately
    # FIXME this slows this method down significantly -- denormalize whole hash to the model on save...?
    attrs[:gml_uniquekey_hash] = self.class.hash_uniquekey(attrs[:gml_uniquekey]) if attrs[:gml_uniquekey].present?

    attrs
  end

  # def self.read_gml_header(gml)
  #   # DRY with Tag.new.gml_document
  #   doc = Nokogiri::XML(self.gml)
  # end

  # TODO: inject 000000book infos into this GML...

  # Dump some chars from the uniquekey as a Secret User Codename
  def secret_username
    return nil if gml_uniquekey_hash.blank?

    "anon-#{gml_uniquekey_hash[-5..]}"
  end

  # Sexify the app name (this could be a helper)
  # TODO: link
  def sexy_app_name
    # puts "gml_application=#{gml_application.inspect} application=#{application.inspect}"
    (application.present? && application) || (gml_application.present? && gml_application) || ''
  end

  # Favorites-related -- TODO this should be elsewhere/via named_scopes
  def favorited_by?(user)
    Favorite.where('object_id = ? AND object_type = ? AND user_id = ?', id, self.class.to_s, user.id).any?
  end

  # Transforms (cached)
  # v2: v1 entries were built before uniqueKey was stripped, so serving one
  # would leak the key the rest of this class works to hide.
  def gml_hash_cache_key
    "tag/#{id}/gml_hash/v2"
  end

  def convert_gml_to_hash
    # Rails.logger.debug "Tag #{id}: convert_gml_to_hash"
    return {} if public_gml.blank?

    # Built from public_gml, not gml_document, so the nested `gml` in a .json
    # response cannot carry the uniqueKey either.
    Hash.from_xml(Nokogiri::XML(public_gml).to_xml)
  rescue StandardError
    Rails.logger.error "ERROR: could not parse GML for Tag #{id} into a hash: #{$ERROR_INFO}"
    {}
  end

  def rotated_gml_cache_key
    "tag/#{id}/rotated_gml"
  end

  def rotate_gml
    # Rails.logger.debug "Tag #{id}: rotate_gml"
    doc = gml_document
    strokes = (doc / 'drawing' / 'stroke')
    strokes.each do |stroke|
      (stroke / 'pt').each do |pt|
        _x = (pt / 'x')[0].content
        (pt / 'x')[0].content = (pt / 'y')[0].content
        (pt / 'y')[0].content = (1.0 - _x.to_f).to_s
      end
    end
    doc
  rescue StandardError
    Rails.logger.error "ERROR: could not rotate GML for #{id}: #{$ERROR_INFO}"
    nil
  end

  # Parse and build errors & warnings
  # Not actually used as a validation, but
  def validate_gml
    # Rails.logger.debug "Tag #{id}: validate_gml"
    doc = gml_document
    errors = []
    warnings = []
    recommendations = []

    # TODO: use nested tags -- e.g. stroke/pt/t rather than just t
    errors << check_for_tag('stroke', "No <stroke> tags - at least 1 stroke required")
    errors << check_for_tag('pt', "No <pt> tags - GML requires at least 1 point. This isn't 'EmptyML'")
    # TODO: iterate through each pt to ensure each has x/y's -- not just any x/y
    errors << check_for_tag('x', "Missing <x> tags inside your <pt>'s")
    errors << check_for_tag('y', "Missing <y> tags inside your <pt>'s")

    # TODO: parse & verify all pt values are between 0 and 1.0

    warnings << check_for_tag('time',
                              "No <time> tags in your <pt> tags! Capturing time data makes things much more interesting.")
    warnings << check_for_tag('client', "No <client> tag - provide some info about your app!")
    warnings << check_for_tag('environment', "No <environment> tag")
    warnings << check_for_tag('up', "No <up> tag in your <environment> - is this horizontal or landscape?!")
    warnings << check_for_tag('screenBounds',
                              "No <screenBounds> tag in your <environment> - otherwise apps might draw it in the wrong aspect ratio")
    # Offset? Rotation? z coords? could be a 'protips' section...
    # Time? Maybe just recommendation?

    recommendations << check_for_tag('uniqueKey',
                                     "No <uniqueKey> tag - includign a unique device ID of some kind lets users pair their 000000book accounts with your app, e.g. iPhone uuid, MAC address, etc")
    unless doc.to_s =~ /\n/
      recommendations << "You don't have any newlines. Proper formatting makes your GML nice & human-readable"
    end
    # assume 2 spaces = 1 tab
    recommendations << "You don't have any tabs. Indenting is the bomb yo" unless doc.to_s =~ /\t/ || doc.to_s =~ /  /
    # Geo information?
  rescue StandardError
    errors << ("Error parsing GML (malformed XML?)#{if Rails.env.development?
                                                      ": #{$ERROR_INFO.class} - #{$ERROR_INFO}"
                                                    end}")
  ensure
    self.validation_results = ActiveSupport::OrderedHash.new
    validation_results[:errors] = errors.compact if errors.present?
    validation_results[:warnings] = warnings.compact if warnings.present?
    validation_results[:recommendations] = recommendations.compact if recommendations.present?

    Rails.logger.debug "GML Validation Results..."
    Rails.logger.debug validation_results.inspect
    return validation_results
  end

  protected

  def create_notification
    Notification.create(subject: self, verb: 'created', user: user)
  end

  # before_create hook to copy over our temp data & then read our GML /
  def build_gml_object
    Rails.logger.debug do
      "Tag #{id}: build_gml_object ... current gml attribute is #{begin
        attributes['gml'].length
      rescue StandardError
        nil
      end} bytes"
    end
    obj = GmlObject.new(tag_id: id) # tag_id nil if we're unsaved, but not if it's old or being fixed
    obj.data = @gml_temp || attributes['gml']
    self.gml_object = obj
    process_gml
    save_header
    find_paired_user
  end

  # after_create hook to finalize the GmlObject
  def save_gml_object
    # Rails.logger.debug "Tag #{id}: save_gml_object..."
    gml_object.tag_id ||= id # FIXME? fail-safe for if you build object pre-save, when tag has no id
    gml_object.save!
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

    gml_header.select do |k, v|
      send("#{k}=", v) if respond_to?(k) && v.present?
      [k, v]
    end.to_hash
    # puts "Tag.save_header: #{attrs.inspect}"
  end

  # assign a user if there's a paired iPhone uniquekey
  def find_paired_user
    Rails.logger.debug { "Tag.find_paired_user: self.gml_uniquekey=#{gml_uniquekey}" }
    return if gml_uniquekey.blank?

    user = User.find_by(iphone_uniquekey: gml_uniquekey)
    return if user.nil?

    Rails.logger.debug { "Pairing with user=#{user.login.inspect}" }
    self.user = user
  end

  # extract some information from the GML
  # and insert our server signature
  # FIXME duplicating some stuff from save_header
  def process_gml
    Rails.logger.debug { "Tag #{id}: process_gml" }
    doc = gml_document
    return if doc.nil?

    header = (doc / 'header')
    if header.blank?
      Rails.logger.error "Tag.process_gml: no header found in GML"
      # TODO: raise exception
      return nil
    end

    attrs = {}
    attrs[:filename] = begin
      (header / 'filename')[0].inner_html
    rescue StandardError
      nil
    end

    obj = begin
      (header / 'client')[0]
    rescue StandardError
      nil
    end
    attrs[:client] = begin
      (obj / 'name').inner_html
    rescue StandardError
      nil
    end

    # STDERR.puts "Tag.process_gml: #{attrs.inspect}"
    # self.application = attrs[:client] unless attrs[:client].blank?
    self.remote_image = attrs[:filename] if attrs[:filename].present?

    attrs
  rescue StandardError
    Rails.logger.error "Tag.process_gml error: #{$ERROR_INFO}"
    nil
  end

  def self.hash_uniquekey(string)
    Digest::SHA1.hexdigest(string)
  end

  def check_for_tag(tag, message)
    @tag_doc ||= gml_document
    return if (@tag_doc / tag).present?

    message
  end

  def check_for_gml_object
    if gml_object.nil?
      Rails.logger.error "ERROR: Missing gml_object for Tag #{id}"
    elsif !gml_object.valid?
      # Rails.logger.warn "Warning: Invalid gml_object for Tag #{self.id}"
    end
  end
end
