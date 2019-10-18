require File.dirname(__FILE__) + '/../spec_helper'

RSpec.describe Visualization, type: :model do

  it "should create" do
    user = FactoryBot.build(:user)
    user.save!
  end

  it "should fail without a login" do
    expect { FactoryBot.create(:user, login: '') }.to raise_error
  end

  it "should fail without an email" do
    expect { FactoryBot.create(:user, email: '') }.to raise_error
  end

end
