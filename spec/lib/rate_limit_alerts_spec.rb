require 'rails_helper'

RSpec.describe RateLimitAlerts do
  # The throttle is the whole reason this module exists. The notification fires
  # once per request over the limit, so without it a client hammering us at
  # 10 req/s would produce 10 emails a second.
  before { Rails.cache.clear }

  describe ".claim" do
    it "succeeds once and then refuses until the window passes" do
      expect(described_class.claim('spec/key', expires_in: 1.hour)).to be(true)
      expect(described_class.claim('spec/key', expires_in: 1.hour)).to be(false)
    end

    it "tracks each client separately" do
      expect(described_class.claim('spec/a', expires_in: 1.hour)).to be(true)
      expect(described_class.claim('spec/b', expires_in: 1.hour)).to be(true)
    end
  end

  describe ".under_global_cap?" do
    it "stops after the cap, so many distinct clients cannot flood us either" do
      results = Array.new(described_class::GLOBAL_CAP + 1) { described_class.under_global_cap? }

      expect(results.count(true)).to eq(described_class::GLOBAL_CAP)
      expect(results.last).to be(false)
    end
  end

  describe ".deliver" do
    it "sends nothing outside production, where there is no SES to send through" do
      expect(described_class).not_to be_enabled

      expect do
        described_class.deliver(scope: 'tags', name: 'writes', by: '198.51.100.7',
                                count: 31, to: 30, within: 1.hour)
      end.not_to change(ActionMailer::Base.deliveries, :size)
    end
  end
end
