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

    it "has many comments" do
      comment = Comment.create!(commentable: tag, user: user, text: 'Test comment')
      expect(tag.comments).to include(comment)
    end

    it "has many likes" do
      like = Like.create!(object: tag, user: user)
      expect(tag.likes).to include(like)
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
