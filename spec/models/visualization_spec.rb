require File.dirname(__FILE__) + '/../spec_helper'

RSpec.describe Visualization, type: :model do

  it "should create" do
    user = FactoryBot.build(:user)
    user.save!
  end

  it "should fail without a login" do
    lambda { FactoryBot.create(:user, login: '') }.should raise_error
  end

  it "should fail without an email" do
    lambda { FactoryBot.create(:user, email: '') }.should raise_error
  end

end
