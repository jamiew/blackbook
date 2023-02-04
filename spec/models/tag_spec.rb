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
    before do
      @tag = FactoryBot.build(:tag_from_api)
    end

    # it "should error on no strokes"
    # it "should error on no points"
    # it "should error on no time data"
    # it "should error on no environment"
    # it "should error on no screenBounds"
    #
    # it "should warn on no header"
    # it "should warn on no environment"
    # it "should warn on no screenBounds"
    # it "should warn on no application"
    # it "should warn on no uniqueKey"
    #
    # it "should recommend using newlines"
    # it "should recommend using tabs"
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

  # Manipulation & transformation
  describe "rotate_gml transformation" do
    # it "should rotate GML data 90 degrees" do
    #   pending
    # end
    #
    # it "should only rotate data from iPhone apps (DustTag, FatTag)" do
    #   pending
    # end
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

end
