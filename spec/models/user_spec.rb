require 'rails_helper'

RSpec.describe User, type: :model do

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

  describe "#deliver_password_reset_instructions!" do
    let(:user){ FactoryBot.create(:user) }

    it "sends an email" do
      expect {
        user.deliver_password_reset_instructions!
      }.to change { ActionMailer::Base.deliveries.count }.by(1)
    end

    it "calls user.reset_perishable_token!" do
      user.should_receive(:reset_perishable_token!)
      user.deliver_password_reset_instructions!
    end
  end

  describe "#reset_perishable_token!" do
    let(:user){ FactoryBot.create(:user) }

    it "changes the user's perishable token" do
      user.perishable_token.should_not be_blank
      expect {
        user.deliver_password_reset_instructions!
      }.to change(user, :perishable_token)
    end
  end

end
