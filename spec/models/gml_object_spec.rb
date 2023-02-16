require 'rails_helper'


RSpec.describe GmlObject, type: :model do

  it 'factory should work' do
    expect {
      FactoryBot.create(:gml_object)
    }.not_to raise_error

    gml = FactoryBot.build(:gml_object)
    expect(gml.valid?).to eq(true)
  end

  it 'should fail to create without a tag_id' do
    expect {
      FactoryBot.create(:gml_object, tag_id: nil)
    }.to raise_error
  end

  it 'should fail to create without any data' do
    expect {
      FactoryBot.create(:gml_object, data: nil)
    }.to raise_error
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
    expect(gml.tag_id).to eq(tag.id)
    expect(gml.data).not_to be_blank
    expect(gml).to be_valid
  end

  it 'should fail if passed a bad Tag object' do
    expect {
      tag = nil
      gml = FactoryBot.create(:gml_object, tag: tag)
      expect(gml).not_to be_valid
    }.to raise_error
  end

  describe "#store_on_disk" do
    it "fails if tag_id is blank" do
      gml = FactoryBot.build(:gml_object, tag_id: nil)
      expect(gml.read_from_disk).to eq(nil)
      expect { gml.store_on_disk }.to raise_error
    end

    it "works" do
      gml = FactoryBot.create(:gml_object)
      expect { gml.store_on_disk }.to_not raise_error

      # TODO would be nice to have method on this object to verify itself
      # maybe use a separate GmlValidator object or concern
      # gml.validate_gml_syntax.should == true
      expect(gml.data).not_to be_blank
      expect(gml.data).to match(/\<gml\>/)

      expect(gml.read_from_disk).to eq(gml.data)
    end
  end

  describe '#read_from_disk' do
    it 'works'

    it "returns nothing if file is missing" do
      # id=1 should always be an invalid "not in production GML" id
      # so use to avoid messy issues because of  `read_from_disk` being called automatically
      gml = FactoryBot.build(:gml_object, tag_id: 1)
      FileUtils.rm_f(gml.filename)
      expect(File.exists?(gml.filename)).to eq(false)
      expect(gml.read_from_disk).to eq(nil)
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
      expect(result).to eq("QmbQJhosiiUUTXk12ueQM79iuWpDohu9WRiige61HqkqtS")
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
      expect(obj.tag.kind_of?(Tag)).to eq(true)
      expect(obj.tag.gml_application).to eq(tag.gml_application)
    end
  end

end
