# == Schema Information
#
# Table name: tags
#
#  id                 :integer(4)      not null, primary key
#  user_id            :integer(4)
#  title              :string(255)
#  slug               :string(255)
#  gml                :text
#  comment_count      :integer(4)
#  likes_count        :integer(4)
#  created_at         :datetime
#  updated_at         :datetime
#  location           :string(255)
#  application        :string(255)
#  set                :string(255)
#  cached_tag_list    :string(255)
#  image_file_name    :string(255)
#  image_content_type :string(255)
#  image_file_size    :integer(4)
#  image_updated_at   :datetime
#  uuid               :string(255)
#  ip                 :string(255)
#  description        :text
#  remote_image       :string(255)
#  remote_secret      :string(255)
#

require File.dirname(__FILE__) + '/../spec_helper'

describe Tag do
  
  # describe 'creation'  
  #   it 'succeed w/ valid GML' do
  #     lambda { Factory.create(:tag, :gml => base_gml.to_s) }.should raise_error
  #   end
  # 
  #   it 'fail w/o GML' do
  #     lambda { Factory.create(:tag, :gml => '') }.should raise_error
  #   end
  # 
  #   it 'fail if GML is invalid' do
  #     lambda { Factory.create(:tag, :gml => '<gmlINVALID></gml>') }.should raise_error
  #   end
  # end
  
  # We should fail tests if we're not pointing at tempt1's tags correctly; this is important
  it 'should be pointing at fffff.at/tempt1 for remote_images' do
    Tag.remote_image_prefix.should == 'http://fffff.at/tempt1/photos/data/eyetags'
  end
  
  # mapping of current GML spec header to database columns; some the same, same duplicated & saved in gml_* namespace
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
      puts tag.inspect
      tag.location.should == 'mylocale'
    end
    
    it 'application => gml_application' do
      pending
    end
    
  end
  
  # describe "location" do
  #   it "can be a lat/long"
  #   it "can be a URL"
  #   it "can be the name of a place/city/etc"
  # end
      
  
protected

  def base_gml
    { 
      :header => {:client => {:name=>'test'} },
      :drawing => { :stroke => {:pt => [{:x=>0,:y=>0,:time=>0}]} }
    }
  end
  
  def create_tag_with_gml_header(attrs)
    merged = base_gml.merge({:header => {:client => attrs}})
    puts "merged=#{merged.inspect}"
    return Factory.create(:tag, :gml => merged.to_xml)
  end
  
end