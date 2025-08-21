require 'rails_helper'

RSpec.describe User, type: :model do

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

  describe "#deliver_password_reset_instructions!" do
    let(:user){ FactoryBot.create(:user) }

    it "sends an email" do
      expect {
        user.deliver_password_reset_instructions!
      }.to change { ActionMailer::Base.deliveries.count }.by(1)
    end

    it "calls user.reset_perishable_token!" do
      expect(user).to receive(:reset_perishable_token!)
      user.deliver_password_reset_instructions!
    end
  end

  describe "#reset_perishable_token!" do
    let(:user){ FactoryBot.create(:user) }

    it "changes the user's perishable token" do
      expect(user.perishable_token).not_to be_blank
      expect {
        user.deliver_password_reset_instructions!
      }.to change(user, :perishable_token)
    end
  end

  describe "Password validation" do
    let(:user) { FactoryBot.create(:user, login: 'testuser', email: 'test@example.com', password: 'password123') }

    it "requires matching password confirmation when password is set" do
      user.password = 'newpassword'
      user.password_confirmation = 'different'
      
      expect(user).not_to be_valid
      expect(user.errors[:password_confirmation]).to be_present
    end

    it "allows password change with matching confirmation" do
      user.password = 'newpassword'
      user.password_confirmation = 'newpassword'
      
      expect(user).to be_valid
    end

    it "doesn't require confirmation when password isn't changed" do
      user.name = 'New Name'
      user.password_confirmation = nil
      
      expect(user).to be_valid
    end
  end

  describe "Unique constraints" do
    let(:user) { FactoryBot.create(:user) }

    it "prevents duplicate logins" do
      duplicate_user = FactoryBot.build(:user, login: user.login)
      expect(duplicate_user).not_to be_valid
      expect(duplicate_user.errors[:login]).to include("is already taken by another user; try a different one.")
    end

    it "prevents duplicate emails" do
      duplicate_user = FactoryBot.build(:user, email: user.email)
      expect(duplicate_user).not_to be_valid
      expect(duplicate_user.errors[:email]).to include("already exists in our system; an email address can only be used once.")
    end

    it "allows blank device keys" do
      user.iphone_uniquekey = nil
      expect(user).to be_valid
      
      user.iphone_uniquekey = ''
      expect(user).to be_valid
    end
  end

end
