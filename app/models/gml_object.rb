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

  IPFS_FOLDER_NAME = "000000book_dev"

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

  def store_on_disk
    filename = "#{Rails.root}/public/gml/#{tag_id}.gml"
    File.open(filename, 'w+') do |file|
      file.write(data)
    end
  end

  def store_on_s3
    # Do some Amazon::SDK and stick it on S3
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

end
