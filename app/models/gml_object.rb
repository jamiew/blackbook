class GmlObject
  attr_accessor :tag_id

  def initialize(**opts)
    # Rails.logger.debug "GmlObject.new opts=#{opts.inspect}"
    self.tag_id = opts[:tag_id]
    self.tag_id ||= opts[:tag]&.try(:id)

    # use data if passed explicitly; otherwise read from disk
    # right?
    self.data = if opts.key?(:data)
                  opts[:data]
                else
                  read_from_disk
                end
  end

  def tag
    @tag ||= Tag.find(tag_id)
  end

  def self.file_dir
    Rails.configuration.x.gml_data_dir.to_s
  end

  def filename
    return nil if tag_id.blank?

    "#{self.class.file_dir}/#{tag_id}.gml"
  end

  def data
    # Rails.logger.debug "*** GmlObject #data..."
    @_data
  end

  def data=(args)
    # Rails.logger.debug "*** GmlObject #data=, #{args.try(:length).inspect} bytes"
    @_data = args
  end

  # FIXME: I don't like this pseudo-ActiveRecord stuff anymore
  def tag=(_tag)
    self.tag_id = _tag.id
  end

  def valid?
    # Rails.logger.debug "GmlObject.valid? data?=#{data.present?} tag?=#{tag_id.present?}"
    data.present? && tag_id.present?
  end

  def self.read_all_cached_gml
    Dir.glob("#{file_dir}/*.gml").each do |path|
      id = path.match(%r{.+/(.+)\.gml})[1]
      tag = Tag.find_by(id: id)
      if tag.nil?
        Rails.logger.warn "Could not find Tag #{id} for path=#{path.inspect}, skipping"
        next
      end

      next if tag.gml_object.present?

      Rails.logger.debug { "No GmlObject for Tag #{id}, creating" }
      tag.send(:build_gml_object) # sorry
      tag.send(:save_gml_object) # really I mean it
    end
  end

  def save
    raise "Oh no you called GmlObject#save"
  end

  def save!
    raise "invalid GmlObject, not saving" unless valid?

    store_on_disk
  end

  def exists_on_disk?
    File.exist?(filename)
  end

  def store_on_disk
    # puts "GmlObject.store_on_disk data[0..100]=#{data[0..100]}"

    if filename.blank?
      Rails.logger.error "Cannot store GmlObject(tag_id=#{tag_id}) on disk, invalid filename. tag_id=#{tag_id.inspect} filename=#{filename.inspect}"
      raise "Filename is blank, cannot store on disk"
    end

    FileUtils.mkdir_p(self.class.file_dir)

    Rails.logger.debug { "GmlObject(tag_id=#{tag_id}).store_on_disk filename=#{filename} ..." }

    File.write(filename, data)
    true
  end

  def read_from_disk
    return nil if filename.blank?
    return nil unless File.exist?(filename)

    data = File.read(filename)
    Rails.logger.debug { "GmlObject(tag_id=#{tag_id}).read_from_disk filename=#{filename} => #{data.length} bytes" }
    data
  end

  def size
    tag.data.length || 0
  end
end
