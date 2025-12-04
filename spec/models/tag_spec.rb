require 'rails_helper'

RSpec.describe Tag, type: :model do

  before do
    # FIXME DRY with TagsController specs...
    # allow_any_instance_of(GmlObject).to receive(:data).and_return(DEFAULT_GML)
  end

  describe 'create' do
    it 'should succeed w/ valid GML' do
      expect { FactoryBot.build(:tag, gml: base_gml.to_s) }.not_to raise_error
    end
  end

  # Important: point at tempt1's tags correctly
  it 'should be pointing at fffff.at/tempt1 for remote_images' do
    expect(Tag.remote_image_prefix).to eq('http://fffff.at/tempt1/photos/data/eyetags')
  end

  # Map some GML headers to database columns
  # Clashing field names are saved into a gml_* namespace
  describe 'reading GML header' do
    it 'should read header/client/name => gml_application' do
      expect(create_tag_with_gml_header(name: 'jdubsatron').gml_application).to eq('jdubsatron')
    end

    it 'should read header/client/username => gml_username' do
      expect(create_tag_with_gml_header(username: 'jamiew').gml_username).to eq('jamiew')
    end

    it 'should read header/client/keywords => gml_keywords' do
      expect(create_tag_with_gml_header(keywords: 'tag,phat,fffffat').gml_keywords).to eq('tag,phat,fffffat')
    end

    it 'should read header/client/uniqueKey => gml_uniquekey' do
      expect(create_tag_with_gml_header(uniqueKey: '#ff00ff').gml_uniquekey).to eq('#ff00ff')
    end

    it 'should read header/client/filename => remote_image' do
      expect(create_tag_with_gml_header(filename: 'image007.jpg').remote_image).to eq(Tag.remote_image_prefix+'/image007.jpg')
    end

    it 'should read header/client/location => location' do
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
      tag = Tag.new(data: gml)
      tag.validate_gml
      expect(tag.validation_results[:errors]).to include("No <stroke> tags - at least 1 stroke required")
    end

    it "errors on no points" do
      gml = "<gml><tag><header><client><name>test</name></client></header><drawing><stroke></stroke></drawing></tag></gml>"
      tag = Tag.new(data: gml)
      tag.validate_gml
      expect(tag.validation_results[:errors]).to include("No <pt> tags - GML requires at least 1 point. This isn't 'EmptyML'")
    end

    it "errors on missing x coordinates" do
      gml = "<gml><tag><header><client><name>test</name></client></header><drawing><stroke><pt><y>0</y><time>0</time></pt></stroke></drawing></tag></gml>"
      tag = Tag.new(data: gml)
      tag.validate_gml
      expect(tag.validation_results[:errors]).to include("Missing <x> tags inside your <pt>'s")
    end

    it "errors on missing y coordinates" do
      gml = "<gml><tag><header><client><name>test</name></client></header><drawing><stroke><pt><x>0</x><time>0</time></pt></stroke></drawing></tag></gml>"
      tag = Tag.new(data: gml)
      tag.validate_gml
      expect(tag.validation_results[:errors]).to include("Missing <y> tags inside your <pt>'s")
    end

    it "warns on no time data" do
      gml = "<gml><tag><header><client><name>test</name></client></header><drawing><stroke><pt><x>0</x><y>0</y></pt></stroke></drawing></tag></gml>"
      tag = Tag.new(data: gml)
      tag.validate_gml
      expect(tag.validation_results[:warnings]).to include("No <time> tags in your <pt> tags! Capturing time data makes things much more interesting.")
    end

    it "warns on no client tag" do
      gml = "<gml><tag><header></header><drawing><stroke><pt><x>0</x><y>0</y><time>0</time></pt></stroke></drawing></tag></gml>"
      tag = Tag.new(data: gml)
      tag.validate_gml
      expect(tag.validation_results[:warnings]).to include("No <client> tag - provide some info about your app!")
    end

    it "warns on no environment tag" do
      gml = "<gml><tag><header><client><name>test</name></client></header><drawing><stroke><pt><x>0</x><y>0</y><time>0</time></pt></stroke></drawing></tag></gml>"
      tag = Tag.new(data: gml)
      tag.validate_gml
      expect(tag.validation_results[:warnings]).to include("No <environment> tag")
    end

    it "warns on no screenBounds tag" do
      gml = "<gml><tag><header><client><name>test</name></client><environment></environment></header><drawing><stroke><pt><x>0</x><y>0</y><time>0</time></pt></stroke></drawing></tag></gml>"
      tag = Tag.new(data: gml)
      tag.validate_gml
      expect(tag.validation_results[:warnings]).to include("No <screenBounds> tag in your <environment> - otherwise apps might draw it in the wrong aspect ratio")
    end

    it "recommends including uniqueKey" do
      gml = "<gml><tag><header><client><name>test</name></client></header><drawing><stroke><pt><x>0</x><y>0</y><time>0</time></pt></stroke></drawing></tag></gml>"
      tag = Tag.new(data: gml)
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
      it "should return a string" do
        expect(@string.class).to eq(String)
        expect(@string).not_to be_blank
      end

      it "should be valid JSON" do
        @json.class == Hash
        expect(@json.length).to be > 0
        # Check for some fields?
      end

      it "should contain GML data (GSON)" do
        expect(@tag.gml_hash).not_to be_blank # Or else there won't be @json['gml']
        expect(@json['gml']).not_to be_blank
      end
    end

    it "to_xml" do
      saved_tag = FactoryBot.create(:tag_from_api)
      xml = saved_tag.to_xml
      expect(xml).not_to be_blank
      expect(xml.to_s).to match(/id/)
    end

    it "gml_document should be a valid Nokogiri document" do
      tag = FactoryBot.build(:tag)
      # tag.gml.should_not be_blank
      allow(tag).to receive(:gml).and_return(DEFAULT_GML) # FIXME use expect() syntax
      doc = tag.gml_document
      expect(doc.class).to eq(Nokogiri::XML::Document)
      expect(doc/'header').not_to be_blank
    end

    it "gml_hash should output a valid Hash" do
      tag = FactoryBot.build(:tag)
      # tag.gml.should_not be_blank
      allow(tag).to receive(:gml).and_return(DEFAULT_GML) # FIXME use expect() syntax
      expect(tag.gml_hash.class).to eq(Hash)
      expect(tag.gml_hash).not_to be_blank
    end
  end

  describe "rotate_gml transformation" do
    it "rotates GML data 90 degrees (swaps x/y, inverts new y)" do
      gml = "<gml><tag><header><client><name>test</name></client></header><drawing><stroke><pt><x>0.25</x><y>0.75</y><time>0</time></pt></stroke></drawing></tag></gml>"
      tag = Tag.new(data: gml)
      rotated = tag.rotate_gml

      pt = (rotated/'drawing'/'stroke'/'pt').first
      # x becomes old y (0.75), y becomes 1 - old x (1 - 0.25 = 0.75)
      expect((pt/'x').text).to eq('0.75')
      expect((pt/'y').text).to eq('0.75')
    end

    it "rotates multiple points correctly" do
      gml = <<~GML
        <gml><tag><header><client><name>test</name></client></header>
        <drawing><stroke>
          <pt><x>0</x><y>1</y><time>0</time></pt>
          <pt><x>1</x><y>0</y><time>1</time></pt>
        </stroke></drawing></tag></gml>
      GML
      tag = Tag.new(data: gml)
      rotated = tag.rotate_gml

      pts = (rotated/'drawing'/'stroke'/'pt')
      # Point 1: x=0, y=1 -> x=1, y=1-0=1
      expect((pts[0]/'x').text).to eq('1')
      expect((pts[0]/'y').text).to eq('1.0')
      # Point 2: x=1, y=0 -> x=0, y=1-1=0
      expect((pts[1]/'x').text).to eq('0')
      expect((pts[1]/'y').text).to eq('0.0')
    end

    it "handles multiple strokes" do
      gml = <<~GML
        <gml><tag><header><client><name>test</name></client></header>
        <drawing>
          <stroke><pt><x>0.5</x><y>0.5</y><time>0</time></pt></stroke>
          <stroke><pt><x>0.2</x><y>0.8</y><time>0</time></pt></stroke>
        </drawing></tag></gml>
      GML
      tag = Tag.new(data: gml)
      rotated = tag.rotate_gml

      strokes = (rotated/'drawing'/'stroke')
      expect(strokes.length).to eq(2)

      pt1 = (strokes[0]/'pt').first
      expect((pt1/'x').text).to eq('0.5')
      expect((pt1/'y').text).to eq('0.5')

      pt2 = (strokes[1]/'pt').first
      expect((pt2/'x').text).to eq('0.8')
      expect((pt2/'y').text).to eq('0.8')
    end

    it "handles GML with no drawing gracefully" do
      tag = Tag.new(data: '<gml><tag><header></header></tag></gml>')
      result = tag.rotate_gml
      expect(result).to be_a(Nokogiri::XML::Document)
    end
  end

  describe "#from_iphone?" do
    it "returns true for DustTag application" do
      tag = Tag.new(gml_application: 'DustTag')
      expect(tag.from_iphone?).to be true
    end

    it "returns true for Fat Tag application" do
      tag = Tag.new(application: 'Fat Tag')
      expect(tag.from_iphone?).to be true
    end

    it "returns true for Katsu application" do
      tag = Tag.new(gml_application: 'Katsu')
      expect(tag.from_iphone?).to be true
    end

    it "returns false for other applications" do
      tag = Tag.new(gml_application: 'Graffiti Analysis')
      expect(tag.from_iphone?).to be false
    end

    it "returns false when no application is set" do
      tag = Tag.new
      expect(tag.from_iphone?).to be false
    end
  end


  protected

  def base_gml
    {
      header: {client: {name:'test'} },
      drawing: { stroke: {pt: [{x:0,y:0,time:0}]} }
    }
  end

  def create_tag_with_gml_header(attrs)
    merged = base_gml.merge({header: {client: attrs}})
    return FactoryBot.create(:tag, gml: merged.to_xml)
  end

  describe "GML validation and processing" do
    let(:valid_gml) { '<gml><tag><header><environment><name>test</name></environment></header><drawing><stroke><pt><x>0</x><y>0</y><time>0</time></pt></stroke></drawing></tag></gml>' }

    it "accepts valid GML" do
      tag = Tag.new(data: valid_gml)
      tag.validate_gml
      
      expect(tag.validation_results).to be_present
      # Should have some validation results
    end

    it "handles malformed XML gracefully" do
      tag = Tag.new(data: '<gml><unclosed_tag>')
      
      expect { tag.validate_gml }.not_to raise_error
    end

    it "extracts GML header information" do
      tag = Tag.new(data: valid_gml)
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

    it "excludes hidden attributes from API output" do
      tag = FactoryBot.create(:tag, ip: '192.168.1.1', remote_secret: 'secret')
      json_output = tag.to_json(except: Tag::HIDDEN_ATTRIBUTES)
      
      expect(json_output).not_to include('192.168.1.1')
      expect(json_output).not_to include('secret')
    end
  end

  describe "Size calculation" do
    let(:valid_gml) { '<gml><tag><header><environment><name>test</name></environment></header><drawing><stroke><pt><x>0</x><y>0</y><time>0</time></pt></stroke></drawing></tag></gml>' }

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
      
      expect(Tag.from_device).to include(device_tag)
      expect(Tag.from_device).not_to include(regular_tag)
    end

    it "distinguishes claimed vs unclaimed tags" do
      user = FactoryBot.create(:user)
      claimed_tag = FactoryBot.create(:tag, gml_uniquekey: 'device123', user: user)
      unclaimed_tag = FactoryBot.create(:tag, gml_uniquekey: 'device456', user: nil)
      
      expect(Tag.claimed).to include(claimed_tag)
      expect(Tag.claimed).not_to include(unclaimed_tag)
      
      expect(Tag.unclaimed).to include(unclaimed_tag)
      expect(Tag.unclaimed).not_to include(claimed_tag)
    end
  end
end
