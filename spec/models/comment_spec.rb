require File.dirname(__FILE__) + '/../spec_helper'

describe Comment do

  before do
    @comment = Factory.build(:comment)

  end

  it "factory should be valid" do
    @comment.should be_valid
    lambda { @comment.save! }.should_not raise_error
  end

  it "should fail without a commentable object" do
    Factory.build(:comment, :commentable => nil).should_not be_valid
  end

  it "should be invalid with blank text" do
    Factory.build(:comment, :text => '').should_not be_valid
  end
end
