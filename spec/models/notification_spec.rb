require 'rails_helper'

RSpec.describe Notification, type: :model do

  before(:each) do
    @user = FactoryBot.create(:user)
    @tag = FactoryBot.create(:tag, user: @user)
    @valid_attributes = {
      subject: @tag,
      verb: "created",
      user: @user
    }
  end

  it "should create a new instance given valid attributes" do
    Notification.create!(@valid_attributes)
  end
end
