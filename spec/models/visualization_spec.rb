require 'rails_helper'

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

  it "fails if you put HTML links in fields" do
    expect(FactoryBot.build(:visualization, authors: '<a href="me.com">it me</a>')).to be_invalid
    expect(FactoryBot.build(:visualization, description: 'more stuff <a href="me.com">it me</a> ok spam')).to be_invalid
  end


end
