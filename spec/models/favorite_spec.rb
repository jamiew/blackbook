require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Favorite do
  before(:each) do
    @favorite = Factory(:favorite)
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
    @user, @tag = Factory(:user), Factory(:tag)
    expect {
      Favorite.create!(:user => @user, :object => @tag)
    }.to change(Notification, :count).by(1)
  end
end
