require 'rails_helper'


RSpec.describe GmlObject, type: :model do

  before(:each) do
    # @gml = FactoryGirl.build(:gml_object)
  end

  it "should not create without a Tag" do
    lambda { FactoryGirl.create(:gml_object, :tag => nil) }.should raise_error
  end

  it 'should not create without any data' do
    lambda { FactoryGirl.create(:gml_object, :data => nil) }.should_not raise_error
  end

  it "should NOT save to disk after saving" do
    gml = FactoryGirl.build(:gml_object)
    expect(gml).to_not receive(:store_on_disk)
    gml.save!
  end

  describe "#store_on_disk" do
    it 'fails if tag_id is blank' do
      gml = FactoryGirl.build(:gml_object, tag_id: nil)
      gml.read_from_disk.should == nil
      expect { gml.store_on_disk }.to raise_error
    end

    it "works" do
      gml = FactoryGirl.create(:gml_object)
      expect { gml.store_on_disk }.to_not raise_error

      # TODO would be nice to have method on this object to verify itself
      # maybe use a separate GmlValidator object or concern
      # gml.validate_gml_syntax.should == true
      gml.data.should_not be_blank
      gml.data.should match(/\<gml\>/)

      gml.read_from_disk.should == gml.data
    end
  end

  describe '#read_from_disk' do
    it 'works'

    it "returns nothing if file is missing" do
      gml = FactoryGirl.create(:gml_object)
      puts "filename=#{gml.filename}"
      File.exists?(gml.filename).should == false
      # FileUtils.rm_f(gml.filename)
      # File.exists?(gml.filename).should == false
      gml.read_from_disk.should == nil
    end
  end

  describe "#store_on_s3" do
    it "works"
  end

  describe "#store_on_ipfs" do
    it "works if IPFS daemon is running"
    it "fails if no IPFS daemon available"
  end

end
