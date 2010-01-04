require File.dirname(__FILE__) + '/../spec_helper'

describe Favorite do
  before(:each) do
    @favorite = Favorite.new
  end

  it "should be valid" do
    pending
    @favorite.should be_valid
  end
end
