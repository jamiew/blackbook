class GmlObject

  attr_accessor :tag_id

  def initialize(**opts)
    # Rails.logger.debug "GmlObject.new opts=#{opts.inspect}"
    self.tag_id = opts[:tag_id]
    self.tag_id ||= opts[:tag] && opts[:tag].try(:id)

    # use data if passed explicitly; otherwise read from disk
    # right?
    if opts.key?(:data)
      self.data = opts[:data]
    else
      self.data = read_from_disk
    end
  end

  def tag
    @tag ||= Tag.find(tag_id)
  end

  def self.file_dir
    "#{Rails.root}/data"
  end

  def filename
    return nil if tag_id.blank?
    "#{self.class.file_dir}/#{tag_id}.gml"
  end

  def s3_file_key
    "gml/#{tag_id}.gml"
  end


  def data
    # Rails.logger.debug "*** GmlObject #data..."
    @_data
  end

  def data=(args)
    # Rails.logger.debug "*** GmlObject #data=, #{args.try(:length).inspect} bytes"
    @_data = args
  end

  # FIXME I don't like this pseudo-ActiveRecord stuff anymore
  def tag=(_tag)
    self.tag_id = _tag.id
  end

  def valid?
    # Rails.logger.debug "GmlObject.valid? data?=#{data.present?} tag?=#{tag_id.present?}"
    data.present? && tag_id.present?
  end

  def self.read_all_cached_gml
    Dir.glob("#{file_dir}/*.gml").each do |path|
      id = path.match(/.+\/(.+)\.gml/)[1]
      tag = Tag.find_by_id(id)
      if tag.nil?
        Rails.logger.warn "Could not find Tag #{id} for path=#{path.inspect}, skipping"
        next
      end

      if tag.gml_object.blank?
        Rails.logger.debug "No GmlObject for Tag #{id}, creating"
        tag.send(:build_gml_object) # sorry
        tag.send(:save_gml_object) # really I mean it
      end
    end
  end

  def save
    raise "Oh no you called GmlObject#save"
  end

  def save!
    # Rails.logger.debug "GmlObject.save! here"
    raise "invalid GmlObject, not saving" unless valid?

    # raise "Oh no you called GmlObject#save!"
    store_on_disk
    # store_on_s3
  end

  def exists_on_disk?
    File.exist?(filename)
  end

  def store_on_disk
    # puts "GmlObject.store_on_disk data[0..100]=#{data[0..100]}"

    if filename.blank?
      Rails.logger.error "Cannot store GmlObject(tag_id=#{tag_id}) on disk, invalid filename. tag_id=#{self.tag_id.inspect} filename=#{filename.inspect}"
      raise "Filename is blank, cannot store on disk"
    end

    unless Dir.exist?(self.class.file_dir)
      FileUtils.mkdir(self.class.file_dir)
    end

    Rails.logger.debug "GmlObject(tag_id=#{tag_id}).store_on_disk filename=#{filename} ..."

    File.open(filename, 'w+') do |file|
      file.write(data)
    end
    return true
  end

  def read_from_disk
    return nil if filename.blank?
    return nil unless File.exist?(filename)
    data = File.read(filename)
    Rails.logger.debug "GmlObject(tag_id=#{tag_id}).read_from_disk filename=#{filename} => #{data.length} bytes"
    return data
  end

  def s3_bucket_name
    ENV['S3_BUCKET']
  end

  def s3
    raise "No S3_BUCKET defined" if s3_bucket_name.blank?
    @s3 ||= Aws::S3::Resource.new
  end

  def s3_object
    @s3_object ||= S3_BUCKET.object(s3_file_key)
  end

  def store_on_s3
    raise "No local GML file to upload (#{filename})" if filename.blank?
    raise "Local GML file is empty, not uploading" if read_from_disk.blank?

		# directly upload from disk...
		# assumes we have stored on this local disk
		# obj.write()
    s3_object.upload_file(filename)

		# # string data
		# obj.put(body: 'Hello World!')

		# # IO object
		# File.open('source', 'rb') do |file|
	 	#		obj.put(body: file)
		# end
  end

  def read_from_s3
    file = s3_object.get
    file.body.read
  end

  def size
    tag.data.length || 0
  end

  # IPFS support
  IPFS_CLIENT_HOST = ENV['IPFS_CLIENT_HOST'] || '127.0.0.1'
  IPFS_CLIENT_PORT = ENV['IPFS_CLIENT_PORT'] || 5001

  def ipfs_client
    @ipfs_client ||= IPFS::Client.new(IPFS_CLIENT_HOST, IPFS_CLIENT_PORT)
  end

  def save_to_ipfs
    raise "invalid GmlObject, not saving" unless valid?
    
    Rails.logger.debug "GmlObject(tag_id=#{tag_id}).save_to_ipfs ..."
    
    begin
      response = ipfs_client.add(data)
      ipfs_hash = response['Hash']
      
      Rails.logger.info "Saved GML to IPFS: #{ipfs_hash}"
      
      # Update the tag with the IPFS hash
      tag.update_column(:ipfs_hash, ipfs_hash) if tag
      
      return ipfs_hash
    rescue => e
      Rails.logger.error "Failed to save to IPFS: #{e.message}"
      raise e
    end
  end

  def read_from_ipfs
    return nil if tag.ipfs_hash.blank?
    
    Rails.logger.debug "GmlObject(tag_id=#{tag_id}).read_from_ipfs hash=#{tag.ipfs_hash} ..."
    
    begin
      response = ipfs_client.cat(tag.ipfs_hash)
      Rails.logger.debug "Read #{response.length} bytes from IPFS"
      return response
    rescue => e
      Rails.logger.error "Failed to read from IPFS: #{e.message}"
      return nil
    end
  end

  def exists_on_ipfs?
    tag.ipfs_hash.present?
  end

end
