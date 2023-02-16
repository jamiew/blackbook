require 'rails_helper'

RSpec.describe Favorite, type: :model do

  before(:each) do
    # FIXME wish this could use :build; not saving associations
    @favorite = FactoryBot.create(:favorite)
  end

  it "should be valid" do
    expect(@favorite).to be_valid
  end

  it "should have a :user" do
    expect(@favorite.user).to be_valid
  end

  it "should have a polymorphic :object" do
    expect(@favorite.object).to be_valid
  end

  it "should make a notification after create" do
    @user = FactoryBot.create(:user)
    @tag = FactoryBot.create(:tag)
    expect {
      Favorite.create!(user: @user, object: @tag)
    }.to change(Notification, :count).by(1)
  end
end
