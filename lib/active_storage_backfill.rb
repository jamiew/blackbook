# Moves Paperclip's files into Active Storage.
#
# Paperclip kept the filename in <attachment>_file_name on the row and the file
# itself at a path derived from the record id. Active Storage keeps a blob row
# and stores the file under its own key, so every original has to be read and
# re-attached. Only originals move: variants are regenerated on demand.
#
#   bin/rails active_storage:verify     # report only, writes nothing
#   bin/rails active_storage:backfill
#
# Safe to re-run. Records that already have an attachment are skipped, so an
# interrupted run picks up where it stopped.
class ActiveStorageBackfill
  # Paperclip's :id_partition, at both widths this app's files actually use.
  #
  # The corpus contains 1,900 files at 9 digits (000/002/062) and 879 at 15
  # (000/000/000/045/135), from different Paperclip versions over the years.
  # Only generating one of them silently skips a third of the images, so every
  # candidate is tried and anything still unfound is reported, never ignored.
  PARTITION_WIDTHS = [9, 15].freeze

  def self.id_partitions(id)
    PARTITION_WIDTHS.map { |w| format("%0#{w}d", id.to_i).scan(/\d{3}/).join('/') }
  end

  ATTACHMENTS = [
    {
      model: 'Tag', name: :image, column: :image_file_name,
      paths: lambda { |r, file|
        id_partitions(r.id).map { |part| "public/system/images/#{part}/original/#{file}" }
      }
    },
    {
      model: 'User', name: :photo, column: :photo_file_name,
      # This one used an explicit :id path, not :id_partition.
      paths: ->(r, file) { ["public/system/photos/#{r.id}/original/#{file}"] }
    },
    {
      model: 'Visualization', name: :image, column: :image_file_name,
      # This one never had an explicit :path, so it used Paperclip's default.
      # Both shapes are tried because the url: option suggested the flatter one.
      paths: lambda { |r, file|
        id_partitions(r.id).map { |part| "public/system/visualizations/images/#{part}/original/#{file}" } +
          ["public/system/visualizations/images/#{r.id}/original/#{file}"]
      }
    }
  ].freeze

  Report = Struct.new(:attached, :skipped, :missing, :failed, keyword_init: true) do
    def print
      puts "\n  attached: #{attached}",
           "  already attached, skipped: #{skipped}",
           "  file not found on disk: #{missing.size}",
           "  errors: #{failed.size}"

      print_problems
    end

    def print_problems
      missing.first(20).each { |m| puts "    missing  #{m}" }
      puts "    ...and #{missing.size - 20} more" if missing.size > 20
      failed.first(20).each { |f| puts "    error    #{f}" }

      return if missing.empty? && failed.empty?

      puts "\n  Nothing was lost: Paperclip's files and columns are untouched.",
           "  Re-run after investigating; already-attached records are skipped."
    end
  end

  def initialize(dry_run: false, root: Rails.root, verbose: true)
    @dry_run = dry_run
    @root = root
    @verbose = verbose
  end

  def run
    report = Report.new(attached: 0, skipped: 0, missing: [], failed: [])

    ATTACHMENTS.each do |config|
      model = config[:model].safe_constantize
      next unless model

      scope = model.where.not(config[:column] => [nil, ''])
      puts "#{config[:model]}##{config[:name]}: #{scope.count} to consider" if @verbose

      scope.find_each { |record| process(record, config, report) }
    end

    report
  end

  private

  def process(record, config, report)
    return report.skipped += 1 if record.public_send(config[:name]).attached?

    filename = record.read_attribute(config[:column])
    path = existing_path(record, config, filename)

    return report.missing << "#{config[:model]}##{record.id} #{filename}" if path.nil?
    return report.attached += 1 if @dry_run

    attach(record, config[:name], path, filename)
    report.attached += 1
  rescue StandardError => e
    report.failed << "#{config[:model]}##{record.id}: #{e.class}: #{e.message}"
  end

  def existing_path(record, config, filename)
    config[:paths].call(record, filename)
                  .map { |p| @root.join(p) }
                  .find { |p| File.file?(p) }
  end

  def attach(record, name, path, filename)
    File.open(path) do |file|
      record.public_send(name).attach(
        io: file, filename: filename, content_type: Marcel::MimeType.for(file, name: filename)
      )
    end
  end
end
