require 'rails_helper'

RSpec.describe Mailer, type: :mailer do

  let(:user){ FactoryBot.create(:user) }

  describe 'password_reset_instructions' do
    it 'works' do
      resp = Mailer.password_reset_instructions(user).deliver
      puts resp.inspect
      resp.body.should match(/If you did not make this request, simply ignore this email/)
      resp.body.should match(/\/password_reset\//)
    end
  end

  describe 'signup_notification' do
    it 'works' do
      resp = Mailer.signup_notification(user)
      puts resp.inspect
      resp.body.should match(/Welcome to Blackbook/)
    end
  end

end
