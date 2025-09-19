# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Mailer, type: :mailer do
  let(:user) { FactoryBot.create(:user) }

  describe 'password_reset_instructions' do
    it 'works' do
      resp = described_class.password_reset_instructions(user)
      expect(resp.body).to match(/If you did not make this request, simply ignore this email/)
      expect(resp.body).to match(%r{/password_reset/})
    end
  end

  describe 'signup_notification' do
    it 'works' do
      resp = described_class.signup_notification(user)
      expect(resp.body).to match(/Welcome to Blackbook/)
    end
  end
end
