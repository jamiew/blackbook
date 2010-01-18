require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe GMLObject do
  before(:each) do
  end

  it "should create a new instance given valid attributes" do
    lambda { Factory.create('GMLObject') }.should_not raise_error
  end
  
  it "should not create without a Tag"
  it 'should not create without any data'  
  it 'should validate GML'
  it 'should not save if GML is invalid'
  
  it 'should read a valid GML header'
  it 'should gracefully handle invalid headers'

  it 'should to_json'
  # Accessors? client, name, uniquekey, etc? 

end
