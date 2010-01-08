require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Gml do
  before(:each) do
    @valid_attributes = {
      :tag_id => 1,
      :data => ,
      :json => 
    }
  end

  it "should create a new instance given valid attributes" do
    Gml.create!(@valid_attributes)
  end
end
