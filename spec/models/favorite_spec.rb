require 'rails_helper'

RSpec.describe Favorite, type: :model do

  before(:each) do
    @favorite = FactoryGirl.build(:favorite)
  end

  it "should be valid" do
    @favorite.should be_valid
  end

  it "should have a :user" do
    @favorite.user.should be_valid
  end

  it "should have a polymorphic :object" do
    @favorite.object.should be_valid
  end

  it "should make a notification after create" do
    @user = FactoryGirl.create(:user)
    @tag = FactoryGirl.create(:tag)
    lambda {
      Favorite.create!(:user => @user, :object => @tag)
    }.should change(Notification, :count).by(1)
  end
end
