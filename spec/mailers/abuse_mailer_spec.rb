require 'rails_helper'

RSpec.describe AbuseMailer do
  describe "#rate_limit_tripped" do
    subject(:mail) do
      described_class.rate_limit_tripped(scope: 'tags', name: 'writes', by: '198.51.100.7',
                                         count: 31, to: 30, within: 1.hour)
    end

    # ApplicationMailer used to hardcode a `default from:` on 000book.com, which
    # overrode the SES-verified sender that production.rb configures.
    it "sends from a domain we actually use" do
      expect(mail.from_addrs.map(&:to_s)).to all(end_with('@000000book.com'))
    end

    it "says who, which limit, and by how much" do
      expect(mail.subject).to eq('[blackbook] Rate limit tripped: writes by 198.51.100.7')
      expect(mail.to).to eq(Rails.application.config.x.alert_recipients)
      expect(mail.body.encoded).to include('198.51.100.7', 'writes', 'tags', '31', '30', '1 hour')
    end
  end
end
