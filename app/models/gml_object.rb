class GmlObject < ActiveRecord::Base

  belongs_to :tag

  validates_presence_of :tag_id, :on => :create, :message => "must have a tag_id"
  validates_uniqueness_of :tag_id, :on => :create, :message => "must be unique"
  validates_associated :tag, :on => :create

  after_save :store_on_disk
  # after_save :store_on_s3
  # after_save :store_on_ipfs

  # FIXME temporarily allowing blank data... I forget why
  # validates_presence_of :data, :on => :create, :message => "can't be blank"

  # TODO validate GML here instead of Tag

  # TODO do we want to partition IPFS folders based on id, like we do locally?
  # e.g. id 501404 becomes approximately dir/501/404
  IPFS_FOLDER_NAME = "000000book_dev"

  def data
    logger.debug "*** GmlObject read data..."
    super
  end

  def data=(args)
    logger.debug "*** GmlObject write data, #{args.try(:length)} bytes"
    super(args)
  end

  def self.read_all_cached_gml
    Dir.glob(Rails.root + 'public/gml-real/*.gml').each do |path|
      id = path.match(/.+\/(.+)\.gml/)[1]
      tag = Tag.find_by_id(id)
      if tag.nil?
        $stderr.puts "Could not find Tag #{id} for path=#{path.inspect}, skipping"
        next
      end

      if tag.gml_object.blank?
        $stderr.puts "No GmlObject for Tag #{id}, creating"
        tag.send(:build_gml_object) # sorry
        tag.send(:save_gml_object) # really I mean it
      end

      tag.gml_object.update_data_from_file(path)
    end
  end

  def store_on_disk(overwrite=false)
    raise "Cannot store on disk, invalid filename" if filename.blank?

    if File.exist?(filename) && overwrite == false
      # TODO maybe raise an exception instead
      # $stderr.puts "GmlObject(id=#{id}).store_on_disk: file exists and overwrite=false, skipping"
      return nil
    end

    logger.info "GmlObject.store_on_disk filename=#{filename} ..."
    File.open(filename, 'w+') do |file|
      file.write(data)
    end
    return true
  end

  def read_from_disk
    # puts "GmlObject.read_from_disk id=#{id.inspect} tag_id=#{tag_id.inspect} ..."
    return nil if filename.blank?
    File.read(filename)
  end

  def store_on_s3
    # Do some Amazon::SDK and stick it on S3
    raise 'Not Yet Implemented'
  end

  def read_from_s3
    raise 'Not Yet Implemented'
  end

  def store_on_ipfs
    # fuck yeah
    # TODO test that daemon is running
    # run as part of Procfile?
    ipfs = IPFS::Connection.new

    folder = IPFS::Upload.folder(IPFS_FOLDER_NAME) do |test|
      test.add_file("#{tag_id}.gml") do |fd|
        fd.write self.data
      end
    end
  end

  def read_from_ipfs
    raise 'Not Yet Implemented'
  end


protected

  def update_data_from_file(path)
    if self.data.present?
      $stderr.puts "GMLObject data exists for tag, #{self.data.size} bytes, skipping"
      return false
    end

    self.data = File.open(path).read
    puts "GmlObject.data now #{self.data.size} bytes"
    success = self.save
    if !success
      $stderr.puts "Error saving GMLObject: #{self.errors.to_json.inspect}"
    end
    success
  end

  def filename
    return nil if tag_id.blank?
    "#{Rails.root}/public/gml/#{tag_id}.gml"
  end


end
