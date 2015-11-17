require File.dirname(__FILE__) + '/../spec_helper'

describe Visualization do

  it "should create" do
    user = Factory.build(:user)
    user.save!
  end

  it "should fail without a login" do
    lambda { Factory.create(:user, :login => '') }.should raise_error
  end

  it "should fail without an email" do
    lambda { Factory.create(:user, :email => '') }.should raise_error
  end

end
