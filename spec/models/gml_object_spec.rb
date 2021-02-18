require 'rails_helper'


RSpec.describe GmlObject, type: :model do

  it 'factory should work' do
    lambda {
      FactoryBot.create(:gml_object)
    }.should_not raise_error

    gml = FactoryBot.build(:gml_object)
    gml.valid?.should == true
  end

  it 'should fail to create without a tag_id' do
    lambda {
      FactoryBot.create(:gml_object, tag_id: nil)
    }.should raise_error
  end

  it 'should fail to create without any data' do
    lambda {
      FactoryBot.create(:gml_object, data: nil)
    }.should raise_error
  end

  it 'should call store_on_disk after_save' do
    gml = FactoryBot.build(:gml_object)
    expect(gml).to receive(:store_on_disk)
    gml.save!
  end

  it 'should pull tag_id from a real Tag object' do
    tag = FactoryBot.create(:tag)
    Rails.logger.debug "OK tag created. id=#{tag.id}"
    gml = FactoryBot.build(:gml_object, tag: tag)
    gml.tag_id.should == tag.id
    gml.data.should_not be_blank
    gml.should be_valid
  end

  it 'should fail if passed a bad Tag object' do
    lambda {
      tag = nil
      gml = FactoryBot.create(:gml_object, tag: tag)
      gml.should_not be_valid
    }.should raise_error
  end

  describe "#store_on_disk" do
    it "fails if tag_id is blank" do
      gml = FactoryBot.build(:gml_object, tag_id: nil)
      gml.read_from_disk.should == nil
      expect { gml.store_on_disk }.to raise_error
    end

    it "works" do
      gml = FactoryBot.create(:gml_object)
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
      # id=1 should always be an invalid "not in production GML" id
      # so use to avoid messy issues because of  `read_from_disk` being called automatically
      gml = FactoryBot.build(:gml_object, tag_id: 1)
      FileUtils.rm_f(gml.filename)
      File.exists?(gml.filename).should == false
      gml.read_from_disk.should == nil
    end
  end

  describe "#store_on_s3" do
    it "works"
  end

  describe "#read_from_s3" do
    it "works"
  end

  describe "#store_on_ipfs" do
    it "works if IPFS daemon is running" do
      if `pidof ipfs`.blank?
        skip "daemon not running, can't test"
      end

      tag = FactoryBot.create(:tag, id: 1)
      gml = FactoryBot.build(:gml_object, tag_id: tag.id)
      result = gml.store_on_ipfs
      # hash of the current public/data/1.gml file =>
      result.should == "QmbQJhosiiUUTXk12ueQM79iuWpDohu9WRiige61HqkqtS"
    end

    it "fails if no IPFS daemon available" do
      # `pkill ipfs && sleep 1` # god forgive me
      # `ps aux | grep ipfs`.should be_blank
      # gml = FactoryBot.build(:gml_object, tag_id: 1)
      # gml_store_on_ipfs
      skip
    end

    it "handles JSON parser errors" do
      # TODO simulate JSON::ParserError
      skip
    end
  end

  describe "#read_from_ipfs" do
    it "works if IPFS daemon is running"
    it "fails if IPFS daemon is not running"
  end

  describe "#tag" do
    it "loads a Tag" do
      tag = FactoryBot.create(:tag)
      obj = FactoryBot.build(:gml_object, tag_id: tag.id)
      obj.tag.kind_of?(Tag).should == true
      obj.tag.gml_application.should == tag.gml_application
    end
  end

end
