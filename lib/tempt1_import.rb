require 'digest'
require 'net/http'
require 'rexml/document'

# Puts the recovered TEMPT1 material back into the database.
#
# Three jobs, each independent and each safe to re-run:
#
#   1. Attach the eyetag images. Tempt's tags were served from fffff.at rather
#      than attached here. That host stopped answering, so all 133 of his tags
#      render broken.
#   2. Replace the truncated GML for tags 108 and 109. MySQL cut both at exactly
#      65535 bytes in 2009, when the column was still TEXT, so neither parses.
#      The repaired copies drop the incomplete final stroke and close the XML,
#      keeping 61 of 62 strokes.
#   3. Create tags for GML that was never uploaded here, found in an EyeWriter
#      robot repository and in a zip from the project team, dated 2010.
#
# The 159 source files are not committed. This import runs once, so carrying 4 MB
# in the history forever to do it would be a poor trade, and deleting them
# afterwards would not shrink anything: git keeps the blobs either way.
#
# They come from a release of the archive instead: one 3.4 MB download, checked
# against BUNDLE_SHA256, unpacked once. Every file is then checked again against
# db/tempt1/manifest.tsv as it is used, so a substituted, truncated or corrupted
# file is refused rather than quietly imported. Set TEMPT1_SOURCE_DIR to a
# checkout of the archive to skip the download entirely.
#
#   bin/rails tempt1:verify     # report only, writes nothing
#   bin/rails tempt1:import
#
# Records that already have what the import would give them are skipped, so an
# interrupted run picks up where it stopped.
class Tempt1Import
  MANIFEST = Rails.root.join('db/tempt1/manifest.tsv')
  # A release tag rather than a branch, so the bytes cannot change under us.
  BUNDLE_URL = 'https://github.com/jamiew/tempt1-archive/releases/download/v1.0/' \
               'tempt1-import-source.tar.gz'.freeze
  BUNDLE_SHA256 = '6204d6ea19edb7dc8ba105c28a81e7707cab779ecb5ba6429f03d1328d7097de'.freeze
  CACHE = Rails.root.join('tmp/tempt1-source')

  LOGIN = 'tempt1'.freeze
  CLIENT = 'eyeSaver-003'.freeze
  TRUNCATED = [108, 109].freeze
  TRUNCATED_BYTES = 65_535

  # Dates come from the capture filenames, temptTag-2010_6_7_14_52_1.gml.
  FILENAME_DATE = /-(\d{4})_(\d{1,2})_(\d{1,2})_(\d{1,2})_(\d{1,2})_(\d{1,2})/
  # The alphabet sheet carries no date. It collects the June and July 2010
  # letters, so it is filed at the end of that run rather than today.
  ATOZ_DATE = Time.utc(2010, 7, 30)

  Entry = Struct.new(:kind, :name, :path, :digest)

  Report = Struct.new(:attached, :skipped, :repaired, :created, :missing, :failed,
                      keyword_init: true) do
    def print
      puts "\n  images attached:   #{attached}",
           "  already had one:   #{skipped}",
           "  GML repaired:      #{repaired}",
           "  tags created:      #{created}",
           "  nothing recovered: #{missing.size}",
           "  errors:            #{failed.size}"
      missing.first(20).each { |m| puts "    missing  #{m}" }
      puts "    ...and #{missing.size - 20} more" if missing.size > 20
      failed.first(20).each { |f| puts "    error    #{f}" }
    end
  end

  def initialize(dry_run: false)
    @dry_run = dry_run
    @report = Report.new(attached: 0, skipped: 0, repaired: 0, created: 0,
                         missing: [], failed: [])
  end

  def run
    attach_eyetags
    repair_truncated
    import_unpublished
    @report
  end

  # A tag is identified by what was drawn, not by what the file was called: the
  # same drawing was uploaded under several names, and several times over.
  def self.fingerprint(gml)
    doc = REXML::Document.new(gml)
    points = REXML::XPath.match(doc, '//pt').filter_map { |point| point_key(point) }
    return nil if points.empty?

    Digest::SHA256.hexdigest(points.join(';'))
  rescue REXML::ParseException
    nil
  end

  # Rounded so files differing only in float formatting still match.
  def self.point_key(point)
    x = point.elements['x']&.text
    y = point.elements['y']&.text
    return nil if x.nil? || y.nil?

    format('%<x>.5f,%<y>.5f', x: Float(x), y: Float(y))
  rescue ArgumentError, TypeError
    nil
  end

  private

  def tempt
    return @tempt if defined?(@tempt)

    @tempt = User.find_by(login: LOGIN)
  end

  def manifest
    @manifest ||= MANIFEST.readlines.filter_map do |line|
      next if line.start_with?('#') || line.strip.empty?

      Entry.new(*line.chomp.split("\t"))
    end
  end

  def entries(kind)
    manifest.select { |e| e.kind == kind }
  end

  def attach_eyetags
    by_name = entries('images').index_by(&:name)
    Tag.where.not(remote_image: [nil, '']).find_each do |tag|
      name = tag.attributes['remote_image'].to_s.sub(/\.gml\z/, '.png')
      next @report.skipped += 1 if tag.image.attached?
      next @report.missing << "tag #{tag.id}: no image recovered for #{name}" unless by_name.key?(name)

      path = fetch(by_name[name])
      next @report.failed << "tag #{tag.id}: could not fetch #{name}" if path.nil?

      attach(tag, path, name) unless @dry_run
      @report.attached += 1
    end
  end

  def attach(tag, path, name)
    tag.image.attach(io: path.open('rb'), filename: name, content_type: 'image/png')
    # These are the files Tempt's own software produced, not renders, and the
    # site labels the two differently.
    tag.image.blob.update!(metadata: tag.image.blob.metadata.merge(generated: false))
  end

  def repair_truncated
    by_name = entries('repaired').index_by(&:name)
    TRUNCATED.each do |id|
      tag = Tag.find_by(id: id)
      entry = by_name["#{id}.gml"]
      next if tag.nil?
      next @report.missing << "no repaired GML for tag #{id}" if entry.nil?
      next if tag.gml.to_s.bytesize != TRUNCATED_BYTES # already replaced

      path = fetch(entry)
      next @report.failed << "tag #{id}: could not fetch repaired GML" if path.nil?

      unless @dry_run
        tag.data = path.read
        tag.save!
      end
      @report.repaired += 1
    end
  end

  # Create tags for drawings that never reached the database. Skipped when the
  # same drawing is already here under any name.
  def import_unpublished
    return @report.failed << "no #{LOGIN} user, cannot import" if tempt.nil?

    known = existing_fingerprints
    entries('unpublished').each do |entry|
      path = fetch(entry)
      next @report.failed << "could not fetch #{entry.name}" if path.nil?

      gml = path.read
      print = self.class.fingerprint(gml)
      next @report.failed << "unparseable: #{entry.name}" if print.nil?
      next if known.include?(print)

      known << print
      create_tag(entry.name, gml) unless @dry_run
      @report.created += 1
    end
  end

  def create_tag(name, gml)
    Tag.create!(
      user: tempt, data: gml, application: CLIENT, gml_application: CLIENT,
      author: LOGIN, created_at: captured_at(name),
      description: "Recovered #{name}. Drawn on the EyeWriter but never " \
                   'uploaded here; see github.com/jamiew/tempt1-archive.'
    )
  rescue StandardError => e
    @report.failed << "#{name}: #{e.message}"
    @report.created -= 1
  end

  def captured_at(name)
    match = FILENAME_DATE.match(name)
    return ATOZ_DATE if match.nil?

    Time.utc(*match.captures.map(&:to_i))
  rescue ArgumentError
    ATOZ_DATE
  end

  def existing_fingerprints
    Tag.where(user_id: tempt.id).or(Tag.where("remote_image LIKE 'temptTag%'"))
       .find_each.filter_map { |t| self.class.fingerprint(t.gml.to_s) }.to_set
  end

  # Local checkout, then cache, then the pinned archive. Verified either way:
  # an unchecked file is how you quietly import the wrong artwork.
  def fetch(entry)
    from_disk(entry) || from_cache(entry)
  end

  def from_disk(entry)
    dir = ENV.fetch('TEMPT1_SOURCE_DIR', nil).presence
    return nil if dir.nil?

    path = Pathname.new(dir).join(entry.path)
    path.exist? && verified?(path, entry.digest) ? path : nil
  end

  def from_cache(entry)
    return nil unless unpacked?

    cached = CACHE.join(entry.path)
    cached.exist? && verified?(cached, entry.digest) ? cached : nil
  end

  # Downloaded and unpacked once per run, not once per file.
  def unpacked?
    return @unpacked if defined?(@unpacked)

    @unpacked = bundle_downloaded? && bundle_unpacked?
  end

  def bundle_downloaded?
    CACHE.mkpath
    tarball = CACHE.join('bundle.tar.gz')
    return true if tarball.exist? && verified?(tarball, BUNDLE_SHA256)

    body = get(BUNDLE_URL)
    if body.nil?
      @report.failed << "could not download #{BUNDLE_URL}"
      return false
    end

    tarball.binwrite(body)
    verified?(tarball, BUNDLE_SHA256)
  end

  def bundle_unpacked?
    return true if CACHE.join('images').directory?

    ok = system('tar', 'xzf', CACHE.join('bundle.tar.gz').to_s, '-C', CACHE.to_s)
    @report.failed << 'could not unpack the source bundle' unless ok
    ok
  end

  # Follows the redirect GitHub issues for release assets.
  def get(url, hops: 3)
    response = Net::HTTP.get_response(URI(url))
    return response.body if response.is_a?(Net::HTTPSuccess)
    return get(response['location'], hops: hops - 1) if response.is_a?(Net::HTTPRedirection) && hops.positive?

    nil
  rescue StandardError
    nil
  end

  def verified?(path, digest)
    return true if Digest::SHA256.file(path).hexdigest == digest

    @report.failed << "#{path.basename} does not match the manifest, refusing it"
    false
  end
end
