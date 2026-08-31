require 'rails_helper'
require Rails.root.join('lib/active_storage_backfill')

RSpec.describe ActiveStorageBackfill do
  # Paperclip laid files out under the record id, at two different widths over
  # the years. Both are recreated here because handling only one silently skips
  # a third of the real corpus.
  let(:root) { Pathname.new(Dir.mktmpdir) }
  let(:png) { Rails.root.join('spec/fixtures/backfill.png') }

  before do
    FileUtils.mkdir_p(png.dirname)
    # A 2x2 PNG is enough; this tests plumbing, not image processing.
    tiny_png = 'iVBORw0KGgoAAAANSUhEUgAAAAIAAAACCAYAAABytg0kAAAAFUlEQVR4nGP8' \
               'z8Dwn4GBgYGJAQ0AABtvAQrpDYPqAAAAAElFTkSuQmCC'
    File.binwrite(png, Base64.decode64(tiny_png))
  end

  after do
    FileUtils.rm_rf(root)
    FileUtils.rm_f(png)
  end

  def place(partition, filename)
    dir = root.join("public/system/images/#{partition}/original")
    FileUtils.mkdir_p(dir)
    FileUtils.cp(png, dir.join(filename))
  end

  def tag_with_filename(id, filename)
    Tag.where(id: id).delete_all
    # insert_all on purpose: production rows predate current validations, and
    # Tag#save! reaches into GmlObject, which is irrelevant here.
    Tag.insert_all([{ id: id, title: "t#{id}", image_file_name: filename, # rubocop:disable Rails/SkipsModelValidations
                      created_at: Time.current, updated_at: Time.current }])
    Tag.find(id)
  end

  describe '.id_partitions' do
    it 'covers both widths seen in the corpus' do
      expect(described_class.id_partitions(2062)).to include('000/002/062')
      expect(described_class.id_partitions(45_135)).to include('000/000/000/045/135')
    end
  end

  describe '#run' do
    it 'attaches a file stored at the 9-digit partition' do
      tag = tag_with_filename(2062, 'shallow.png')
      place('000/002/062', 'shallow.png')

      report = described_class.new(root: root, verbose: false).run

      expect(report.attached).to eq(1)
      expect(report.missing).to be_empty
      expect(tag.reload.image).to be_attached
      expect(tag.image.byte_size).to eq(File.size(png))
    end

    it 'attaches a file stored at the 15-digit partition' do
      tag = tag_with_filename(45_135, 'deep.png')
      place('000/000/000/045/135', 'deep.png')

      described_class.new(root: root, verbose: false).run

      expect(tag.reload.image).to be_attached
    end

    it 'reports a row whose file is missing instead of failing silently' do
      tag_with_filename(999, 'gone.png')

      report = described_class.new(root: root, verbose: false).run

      expect(report.attached).to eq(0)
      expect(report.missing.join).to include('Tag#999', 'gone.png')
    end

    it 'is safe to run twice' do
      tag = tag_with_filename(2062, 'shallow.png')
      place('000/002/062', 'shallow.png')

      described_class.new(root: root, verbose: false).run
      second = described_class.new(root: root, verbose: false).run

      expect(second.attached).to eq(0)
      expect(second.skipped).to eq(1)
      expect(tag.reload.image.attachments.size).to eq(1)
    end

    it 'writes nothing when asked only to report' do
      tag = tag_with_filename(2062, 'shallow.png')
      place('000/002/062', 'shallow.png')

      report = described_class.new(root: root, dry_run: true, verbose: false).run

      expect(report.attached).to eq(1)
      expect(tag.reload.image).not_to be_attached
    end
  end
end
