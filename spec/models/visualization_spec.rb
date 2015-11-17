require File.dirname(__FILE__) + '/../spec_helper'

RSpec.describe Visualization, type: :model do

  it "should create" do
    user = FactoryGirl.build(:user)
    user.save!
  end

  it "should fail without a login" do
    lambda { FactoryGirl.create(:user, :login => '') }.should raise_error
  end

  it "should fail without an email" do
    lambda { FactoryGirl.create(:user, :email => '') }.should raise_error
  end

end
