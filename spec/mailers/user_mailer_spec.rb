require 'rails_helper'

RSpec.describe UserMailer, type: :mailer do
  let(:user) { FactoryBot.create(:user) }

  describe 'password_reset_instructions' do
    it 'includes the reset link and the ignore-this notice' do
      resp = described_class.password_reset_instructions(user)
      expect(resp.body).to include('If you did not make this request, simply ignore this email')
      expect(resp.body).to include('/password_reset/')
    end
  end

  describe 'signup_notification' do
    it 'welcomes the new user' do
      resp = described_class.signup_notification(user)
      expect(resp.body).to include('Welcome to Blackbook')
    end
  end
end
