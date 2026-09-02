require 'rails_helper'

RSpec.describe Tag, type: :model do
  describe 'create' do
    it 'succeeds w/ valid GML' do
      expect { FactoryBot.build(:tag, gml: base_gml.to_s) }.not_to raise_error
    end
  end

  # Important: point at tempt1's tags correctly
  it 'is pointing at fffff.at/tempt1 for remote_images' do
    expect(described_class.remote_image_prefix).to eq('http://fffff.at/tempt1/photos/data/eyetags')
  end

  # Map some GML headers to database columns
  # Clashing field names are saved into a gml_* namespace
  describe 'reading GML header' do
    it 'reads header/client/name => gml_application' do
      expect(create_tag_with_gml_header(name: 'jdubsatron').gml_application).to eq('jdubsatron')
    end

    it 'reads header/client/username => gml_username' do
      expect(create_tag_with_gml_header(username: 'jamiew').gml_username).to eq('jamiew')
    end

    it 'reads header/client/keywords => gml_keywords' do
      expect(create_tag_with_gml_header(keywords: 'tag,phat,fffffat').gml_keywords).to eq('tag,phat,fffffat')
    end

    it 'reads header/client/uniqueKey => gml_uniquekey' do
      expect(create_tag_with_gml_header(uniqueKey: '#ff00ff').gml_uniquekey).to eq('#ff00ff')
    end

    it 'reads header/client/filename => remote_image' do
      expect(create_tag_with_gml_header(filename: 'image007.jpg').remote_image).to eq("#{described_class.remote_image_prefix}/image007.jpg")
    end

    it 'reads header/client/location => location' do
      expect(create_tag_with_gml_header(location: 'http://google.com').location).to eq('http://google.com')
    end
  end

  # various GML headers are saved back onto the model each time
  describe 'saving GML header fields' do
    it 'location => location' do
      tag = create_tag_with_gml_header(location: 'mylocale')
      expect(tag.location).to eq('mylocale')
    end
  end

  describe "validating GML" do
    it "errors on no strokes" do
      gml = "<gml><tag><header><client><name>test</name></client></header><drawing></drawing></tag></gml>"
      tag = described_class.new(data: gml)
      tag.validate_gml
      expect(tag.validation_results[:errors]).to include("No <stroke> tags - at least 1 stroke required")
    end

    it "errors on no points" do
      gml = "<gml><tag><header><client><name>test</name></client></header><drawing><stroke></stroke></drawing></tag></gml>"
      tag = described_class.new(data: gml)
      tag.validate_gml
      expect(tag.validation_results[:errors]).to include("No <pt> tags - GML requires at least 1 point. This isn't 'EmptyML'")
    end

    it "errors on missing x coordinates" do
      gml = "<gml><tag><header><client><name>test</name></client></header><drawing><stroke><pt><y>0</y><time>0</time></pt></stroke></drawing></tag></gml>"
      tag = described_class.new(data: gml)
      tag.validate_gml
      expect(tag.validation_results[:errors]).to include("Missing <x> tags inside your <pt>'s")
    end

    it "errors on missing y coordinates" do
      gml = "<gml><tag><header><client><name>test</name></client></header><drawing><stroke><pt><x>0</x><time>0</time></pt></stroke></drawing></tag></gml>"
      tag = described_class.new(data: gml)
      tag.validate_gml
      expect(tag.validation_results[:errors]).to include("Missing <y> tags inside your <pt>'s")
    end

    it "warns on no time data" do
      gml = "<gml><tag><header><client><name>test</name></client></header><drawing><stroke><pt><x>0</x><y>0</y></pt></stroke></drawing></tag></gml>"
      tag = described_class.new(data: gml)
      tag.validate_gml
      expect(tag.validation_results[:warnings]).to include("No <time> tags in your <pt> tags! Capturing time data makes things much more interesting.")
    end

    it "warns on no client tag" do
      gml = "<gml><tag><header></header><drawing><stroke><pt><x>0</x><y>0</y><time>0</time></pt></stroke></drawing></tag></gml>"
      tag = described_class.new(data: gml)
      tag.validate_gml
      expect(tag.validation_results[:warnings]).to include("No <client> tag - provide some info about your app!")
    end

    it "warns on no environment tag" do
      gml = "<gml><tag><header><client><name>test</name></client></header><drawing><stroke><pt><x>0</x><y>0</y><time>0</time></pt></stroke></drawing></tag></gml>"
      tag = described_class.new(data: gml)
      tag.validate_gml
      expect(tag.validation_results[:warnings]).to include("No <environment> tag")
    end

    it "warns on no screenBounds tag" do
      gml = "<gml><tag><header><client><name>test</name></client><environment></environment></header><drawing><stroke><pt><x>0</x><y>0</y><time>0</time></pt></stroke></drawing></tag></gml>"
      tag = described_class.new(data: gml)
      tag.validate_gml
      expect(tag.validation_results[:warnings]).to include("No <screenBounds> tag in your <environment> - otherwise apps might draw it in the wrong aspect ratio")
    end

    it "recommends including uniqueKey" do
      gml = "<gml><tag><header><client><name>test</name></client></header><drawing><stroke><pt><x>0</x><y>0</y><time>0</time></pt></stroke></drawing></tag></gml>"
      tag = described_class.new(data: gml)
      tag.validate_gml
      expect(tag.validation_results[:recommendations]).to include("No <uniqueKey> tag - includign a unique device ID of some kind lets users pair their 000000book accounts with your app, e.g. iPhone uuid, MAC address, etc")
    end
  end

  describe "format conversion" do
    before do
      @tag = FactoryBot.build(:tag)
    end

    describe "to_json" do
      before do
        @string = @tag.to_json
        @json = ActiveSupport::JSON.decode(@string)
      end

      # I feel like this should actually return a hash >:|
      it "returns a string" do
        expect(@string.class).to eq(String)
        expect(@string).not_to be_blank
      end

      it "is valid JSON" do
        expect(@json).to be_a(Hash)
        expect(@json.length).to be > 0
      end

      it "contains GML data (GSON)" do
        expect(@tag.gml_hash).not_to be_blank # Or else there won't be @json['gml']
        expect(@json['gml']).not_to be_blank
      end
    end

    it "to_xml" do
      saved_tag = FactoryBot.create(:tag_from_api)
      xml = saved_tag.to_xml
      expect(xml).not_to be_blank
      expect(xml.to_s).to include('id')
    end

    it "gml_document should be a valid Nokogiri document" do
      tag = FactoryBot.build(:tag)
      # tag.gml.should_not be_blank
      allow(tag).to receive(:gml).and_return(DEFAULT_GML) # FIXME: use expect() syntax
      doc = tag.gml_document
      expect(doc.class).to eq(Nokogiri::XML::Document)
      expect(doc / 'header').not_to be_blank
    end

    it "gml_hash should output a valid Hash" do
      tag = FactoryBot.build(:tag)
      # tag.gml.should_not be_blank
      allow(tag).to receive(:gml).and_return(DEFAULT_GML) # FIXME: use expect() syntax
      expect(tag.gml_hash.class).to eq(Hash)
      expect(tag.gml_hash).not_to be_blank
    end
  end

  describe "rotate_gml transformation" do
    it "rotates GML data 90 degrees (swaps x/y, inverts new y)" do
      gml = "<gml><tag><header><client><name>test</name></client></header><drawing><stroke><pt><x>0.25</x><y>0.75</y><time>0</time></pt></stroke></drawing></tag></gml>"
      tag = described_class.new(data: gml)
      rotated = tag.rotate_gml

      pt = (rotated / 'drawing' / 'stroke' / 'pt').first
      # x becomes old y (0.75), y becomes 1 - old x (1 - 0.25 = 0.75)
      expect((pt / 'x').text).to eq('0.75')
      expect((pt / 'y').text).to eq('0.75')
    end

    it "rotates multiple points correctly" do
      gml = <<~GML
        <gml><tag><header><client><name>test</name></client></header>
        <drawing><stroke>
          <pt><x>0</x><y>1</y><time>0</time></pt>
          <pt><x>1</x><y>0</y><time>1</time></pt>
        </stroke></drawing></tag></gml>
      GML
      tag = described_class.new(data: gml)
      rotated = tag.rotate_gml

      pts = (rotated / 'drawing' / 'stroke' / 'pt')
      # Point 1: x=0, y=1 -> x=1, y=1-0=1
      expect((pts[0] / 'x').text).to eq('1')
      expect((pts[0] / 'y').text).to eq('1.0')
      # Point 2: x=1, y=0 -> x=0, y=1-1=0
      expect((pts[1] / 'x').text).to eq('0')
      expect((pts[1] / 'y').text).to eq('0.0')
    end

    it "handles multiple strokes" do
      gml = <<~GML
        <gml><tag><header><client><name>test</name></client></header>
        <drawing>
          <stroke><pt><x>0.5</x><y>0.5</y><time>0</time></pt></stroke>
          <stroke><pt><x>0.2</x><y>0.8</y><time>0</time></pt></stroke>
        </drawing></tag></gml>
      GML
      tag = described_class.new(data: gml)
      rotated = tag.rotate_gml

      strokes = (rotated / 'drawing' / 'stroke')
      expect(strokes.length).to eq(2)

      pt1 = (strokes[0] / 'pt').first
      expect((pt1 / 'x').text).to eq('0.5')
      expect((pt1 / 'y').text).to eq('0.5')

      pt2 = (strokes[1] / 'pt').first
      expect((pt2 / 'x').text).to eq('0.8')
      expect((pt2 / 'y').text).to eq('0.8')
    end

    it "handles GML with no drawing gracefully" do
      tag = described_class.new(data: '<gml><tag><header></header></tag></gml>')
      result = tag.rotate_gml
      expect(result).to be_a(Nokogiri::XML::Document)
    end
  end

  describe "#from_iphone?" do
    it "returns true for DustTag application" do
      tag = described_class.new(gml_application: 'DustTag')
      expect(tag.from_iphone?).to be true
    end

    it "returns true for Fat Tag application" do
      tag = described_class.new(application: 'Fat Tag')
      expect(tag.from_iphone?).to be true
    end

    it "returns true for Katsu application" do
      tag = described_class.new(gml_application: 'Katsu')
      expect(tag.from_iphone?).to be true
    end

    it "returns false for other applications" do
      tag = described_class.new(gml_application: 'Graffiti Analysis')
      expect(tag.from_iphone?).to be false
    end

    it "returns false when no application is set" do
      tag = described_class.new
      expect(tag.from_iphone?).to be false
    end
  end

  describe '#player_data' do
    it 'flattens strokes into [x, y, time] triples' do
      tag = tag_with_gml(<<~GML)
        <drawing><stroke>
          <pt><x>0.25</x><y>0.5</y><time>0</time></pt>
          <pt><x>0.75</x><y>0.5</y><time>0.4</time></pt>
        </stroke></drawing>
      GML

      expect(tag.player_data[:strokes].first[:points]).to eq([[0.25, 0.5, 0.0], [0.75, 0.5, 0.4]])
    end

    it 'keeps a single stroke and a list of strokes in the same shape' do
      one = tag_with_gml('<drawing><stroke><pt><x>0</x><y>0</y><time>0</time></pt></stroke></drawing>')
      two = tag_with_gml(<<~GML)
        <drawing>
          <stroke><pt><x>0</x><y>0</y><time>0</time></pt></stroke>
          <stroke><pt><x>1</x><y>1</y><time>1</time></pt></stroke>
        </drawing>
      GML

      expect(one.player_data[:strokes].size).to eq(1)
      expect(two.player_data[:strokes].size).to eq(2)
    end

    it 'drops points with unreadable coordinates' do
      tag = tag_with_gml(<<~GML)
        <drawing><stroke>
          <pt><x>0.1</x><y>0.1</y><time>0</time></pt>
          <pt><x>banana</x><y>0.2</y><time>0.1</time></pt>
        </stroke></drawing>
      GML

      expect(tag.player_data[:strokes].first[:points].size).to eq(1)
    end
  end

  # The old player decided this from the client's name, which is wrong in both
  # directions: the same app wrote landscape captures on early phones and
  # upright ones later. GML records the orientation, so read it.
  describe '#landscape_capture?' do
    it 'is true when the up vector points along x' do
      expect(tag_with_environment(up_x: 1, up_y: 0).player_data[:rotate]).to be true
    end

    it 'is false when the up vector points along y' do
      expect(tag_with_environment(up_x: 0, up_y: 1).player_data[:rotate]).to be false
    end

    it 'is false when no up vector was recorded' do
      expect(tag_with_gml('<drawing><stroke><pt><x>0</x><y>0</y><time>0</time></pt></stroke></drawing>')
               .player_data[:rotate]).to be false
    end
  end

  protected

  def tag_with_gml(body)
    FactoryBot.create(:tag, gml: "<gml><tag><header><client><name>test</name></client></header>#{body}</tag></gml>")
  end

  def tag_with_environment(up_x:, up_y:)
    tag_with_gml(<<~GML)
      <environment><up><x>#{up_x}</x><y>#{up_y}</y><z>0</z></up></environment>
      <drawing><stroke><pt><x>0</x><y>0</y><time>0</time></pt></stroke></drawing>
    GML
  end

  def base_gml
    {
      header: { client: { name: 'test' } },
      drawing: { stroke: { pt: [{ x: 0, y: 0, time: 0 }] } }
    }
  end

  def create_tag_with_gml_header(attrs)
    merged = base_gml.merge({ header: { client: attrs } })
    FactoryBot.create(:tag, gml: merged.to_xml)
  end

  describe "GML validation and processing" do
    let(:valid_gml) do
      '<gml><tag><header><environment><name>test</name></environment></header><drawing><stroke><pt><x>0</x><y>0</y><time>0</time></pt></stroke></drawing></tag></gml>'
    end

    it "accepts valid GML" do
      tag = described_class.new(data: valid_gml)
      tag.validate_gml

      expect(tag.validation_results).to be_present
      # Should have some validation results
    end

    it "handles malformed XML gracefully" do
      tag = described_class.new(data: '<gml><unclosed_tag>')

      expect { tag.validate_gml }.not_to raise_error
    end

    it "extracts GML header information" do
      tag = described_class.new(data: valid_gml)
      header = tag.gml_header

      expect(header).to be_a(Hash)
      # GML header extraction returns basic info
      expect(header).to be_present
    end
  end

  describe "XML output filtering" do
    it "excludes blank attributes from XML output" do
      tag = FactoryBot.create(:tag, title: 'Test', description: nil, location: '')
      xml_output = tag.to_xml

      expect(xml_output).to include('title')
      expect(xml_output).not_to include('description')
      expect(xml_output).not_to include('location')
    end

    it "excludes private attributes from API output, without being asked to" do
      tag = FactoryBot.create(:tag, ip: '192.168.1.1', remote_secret: 'secret',
                                    gml_uniquekey: 'DEVICE-KEY', gml_uniquekey_hash: 'HASHED',
                                    cached_tag_list: 'listed', user: FactoryBot.create(:user))

      %i[to_json to_xml].each do |format|
        output = tag.public_send(format)
        %w[192.168.1.1 secret DEVICE-KEY HASHED listed user_id].each do |private_value|
          expect(output).not_to include(private_value), "#{format} leaked #{private_value}"
        end
      end
    end

    it "strips the device uniqueKey from the GML it serves, in every format" do
      gml_with_key = '<gml><tag><header><client><name>app</name>' \
                     '<uniqueKey>DEVICE-KEY-XYZ</uniqueKey></client></header>' \
                     '<drawing><stroke><pt><x>0</x><y>0</y><time>0</time></pt></stroke></drawing></tag></gml>'
      tag = FactoryBot.create(:tag, data: gml_with_key)

      expect(tag.gml).to include('DEVICE-KEY-XYZ') # still readable internally
      expect(tag.public_gml).not_to include('DEVICE-KEY-XYZ')
      expect(tag.to_json).not_to include('DEVICE-KEY-XYZ')
      expect(tag.gml_hash.to_s).not_to include('DEVICE-KEY-XYZ')
    end

    it "still reads the uniqueKey on upload, or device pairing breaks" do
      gml_with_key = '<gml><tag><header><client><name>app</name>' \
                     '<uniqueKey>DEVICE-KEY-XYZ</uniqueKey></client></header>' \
                     '<drawing><stroke><pt><x>0</x><y>0</y><time>0</time></pt></stroke></drawing></tag></gml>'
      tag = FactoryBot.create(:tag, data: gml_with_key)

      expect(tag.gml_header[:gml_uniquekey]).to eq('DEVICE-KEY-XYZ')
    end

    # The guard. Adding a column now forces a decision about whether the API
    # publishes it, rather than publishing it by default and finding out later.
    it "classifies every column as either public or private" do
      classified = described_class::PUBLIC_ATTRIBUTES + described_class::PRIVATE_ATTRIBUTES
      unclassified = described_class.column_names - classified

      expect(unclassified).to be_empty,
                              "not in PUBLIC_ATTRIBUTES or PRIVATE_ATTRIBUTES: #{unclassified.join(', ')}"
      expect(classified - described_class.column_names).to be_empty
      expect(described_class::PUBLIC_ATTRIBUTES & described_class::PRIVATE_ATTRIBUTES).to be_empty
    end

    it "publishes every allowlisted attribute that has a value" do
      tag = FactoryBot.create(:tag, title: 'Burner', application: 'Fatline', location: 'NYC')
      json = tag.as_json

      # as_json adds :gml as a symbol key alongside the string attribute names
      keys = json.keys.map(&:to_s)
      expect(keys).to include('id', 'title', 'application', 'location', 'created_at')
      expect(keys - (Tag::PUBLIC_ATTRIBUTES + ['gml'])).to be_empty
    end
  end

  describe "Size calculation" do
    let(:valid_gml) do
      '<gml><tag><header><environment><name>test</name></environment></header><drawing><stroke><pt><x>0</x><y>0</y><time>0</time></pt></stroke></drawing></tag></gml>'
    end

    it "calculates size from GML data" do
      tag = FactoryBot.create(:tag, data: valid_gml)

      expect(tag.gml_object.size).to eq(valid_gml.length)
    end
  end

  describe "Associations" do
    let(:user) { FactoryBot.create(:user) }
    let(:tag) { FactoryBot.create(:tag, user: user) }

    it "belongs to a user" do
      expect(tag.user).to eq(user)
    end

    it "can be favorited" do
      favorite = Favorite.create!(object: tag, user: user)
      expect(tag.favorites).to include(favorite)
    end
  end

  describe "Scopes" do
    it "finds device tags" do
      device_tag = FactoryBot.create(:tag, gml_uniquekey: 'device123')
      regular_tag = FactoryBot.create(:tag, gml_uniquekey: nil)

      expect(described_class.from_device).to include(device_tag)
      expect(described_class.from_device).not_to include(regular_tag)
    end

    it "distinguishes claimed vs unclaimed tags" do
      user = FactoryBot.create(:user)
      claimed_tag = FactoryBot.create(:tag, gml_uniquekey: 'device123', user: user)
      unclaimed_tag = FactoryBot.create(:tag, gml_uniquekey: 'device456', user: nil)

      expect(described_class.claimed).to include(claimed_tag)
      expect(described_class.claimed).not_to include(unclaimed_tag)

      expect(described_class.unclaimed).to include(unclaimed_tag)
      expect(described_class.unclaimed).not_to include(claimed_tag)
    end
  end
end
