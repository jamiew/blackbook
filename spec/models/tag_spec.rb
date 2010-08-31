require File.dirname(__FILE__) + '/../spec_helper'

describe Tag do

  describe 'create' do
    it 'should succeed w/ valid GML' do
      expect { Factory.create(:tag, :gml => base_gml.to_s) }.to_not raise_error
    end
  end

  # Important: point at tempt1's tags correctly
  it 'should be pointing at fffff.at/tempt1 for remote_images' do
    Tag.remote_image_prefix.should == 'http://fffff.at/tempt1/photos/data/eyetags'
  end

  # Map some GML headers to database columns
  # Clashing field names are saved into a gml_* namespace
  describe 'reading GML header' do
    it 'should read header/client/name => gml_application' do; create_tag_with_gml_header(:name => 'jdubsatron').gml_application.should == 'jdubsatron'; end
    it 'should read header/client/username => gml_username' do; create_tag_with_gml_header(:username => 'jamiew').gml_username.should == 'jamiew'; end
    it 'should read header/client/keywords => gml_keywords' do; create_tag_with_gml_header(:keywords => 'tag,phat,fffffat').gml_keywords.should == 'tag,phat,fffffat'; end
    it 'should read header/client/uniqueKey => gml_uniquekey' do; create_tag_with_gml_header(:uniqueKey => '#ff00ff').gml_uniquekey.should == '#ff00ff'; end
    it 'should read header/client/filename => remote_image' do; create_tag_with_gml_header(:filename => 'image007.jpg').remote_image.should == Tag.remote_image_prefix+'/image007.jpg'; end
    it 'should read header/client/location => location' do; create_tag_with_gml_header(:location => 'http://google.com').location.should == 'http://google.com'; end
  end

  # various GML headers are saved back onto the model each time
  describe 'saving GML header fields' do
    it 'location => location' do
      tag = create_tag_with_gml_header(:location => 'mylocale')
      tag.location.should == 'mylocale'
    end
  end

  # Alternate formats
  describe "to_json" do
    it "should be valid" do
      pending
    end

    it "should include GML data" do
      pending
    end
  end

  describe "to_xml" do
    it "should be valid" do
      pending
    end
  end

  describe "to_hash" do
    it "should be valid" do
      pending
    end
  end

  # Transforms
  describe "rotate_gml" do
    it "should rotate GML data 90 degrees" do
      pending
    end

    it "should only rotate data from iPhone apps (DustTag, FatTag)" do
      pending
    end
  end

  describe "validate_gml" do
    before
      @tag = Factory.create(:tag)
    end

    it "should error on no strokes"
    it "should error on no points"
    it "should error on no time data"
    it "should error on no environment"
    it "should error on no screenBounds"

    it "should warn on no header"
    it "should warn on no environment"
    it "should warn on no screenBounds"
    it "should warn on no application"
    it "should warn on no uniqueKey"
  end

  protected

  def base_gml
    {
      :header => {:client => {:name=>'test'} },
      :drawing => { :stroke => {:pt => [{:x=>0,:y=>0,:time=>0}]} }
    }
  end

  def create_tag_with_gml_header(attrs)
    merged = base_gml.merge({:header => {:client => attrs}})
    return Factory.create(:tag, :gml => merged.to_xml)
  end

end
