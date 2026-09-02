require 'rails_helper'
require Rails.root.join('lib/tempt1_import')

RSpec.describe Tempt1Import do
  describe '.fingerprint' do
    let(:gml) do
      <<~GML
        <GML><tag><drawing><stroke>
          <pt><x>0.1</x><y>0.2</y><time>0</time></pt>
          <pt><x>0.3</x><y>0.4</y><time>1</time></pt>
        </stroke></drawing></tag></GML>
      GML
    end

    it 'identifies a drawing by its coordinates, not its filename' do
      renamed = gml.sub('<GML>', "<GML><!-- different file -->\n")
      expect(described_class.fingerprint(renamed)).to eq(described_class.fingerprint(gml))
    end

    it 'separates drawings that differ' do
      moved = gml.sub('<x>0.3</x>', '<x>0.9</x>')
      expect(described_class.fingerprint(moved)).not_to eq(described_class.fingerprint(gml))
    end

    it 'ignores timing, which capture apps recorded inconsistently' do
      retimed = gml.sub('<time>1</time>', '<time>99</time>')
      expect(described_class.fingerprint(retimed)).to eq(described_class.fingerprint(gml))
    end

    it 'returns nil for GML it cannot parse, rather than a hash of nothing' do
      expect(described_class.fingerprint('<GML><tag><drawing>')).to be_nil
      expect(described_class.fingerprint('')).to be_nil
    end
  end

  describe '#run' do
    before { FactoryBot.create(:user, login: 'tempt1') }

    it 'reports without writing when asked to verify' do
      expect { described_class.new(dry_run: true).run }.not_to change(Tag, :count)
    end

    it 'skips a tag that already has an image attached' do
      tag = FactoryBot.create(:tag, remote_image: 'temptTag-2009_8_23_13_21_12.gml')
      tag.image.attach(io: StringIO.new('x'), filename: 'a.png', content_type: 'image/png')

      expect(described_class.new(dry_run: true).run.skipped).to be >= 1
    end

    it 'leaves a tag alone when the recovered image is not on disk' do
      FactoryBot.create(:tag, remote_image: 'temptTag-not-recovered.gml')
      report = described_class.new(dry_run: true).run

      expect(report.missing).to include(/temptTag-not-recovered\.png/)
    end
  end
end
