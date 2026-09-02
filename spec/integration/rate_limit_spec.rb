require 'rails_helper'

RSpec.describe "Rate limiting", type: :request do
  let(:valid_gml) do
    '<gml><tag><header><environment><name>test</name></environment></header>' \
      '<drawing><stroke><pt><x>0</x><y>0</y><time>0</time></pt></stroke></drawing></tag></gml>'
  end

  def upload(format: nil)
    post "/data#{format}", params: { gml: valid_gml, application: 'TestApp' }
  end

  describe "uploads" do
    it "allows the first 30 in an hour and refuses the 31st" do
      30.times { upload }
      expect(response).to have_http_status(:ok)

      expect { upload }.not_to change(Tag, :count)
      expect(response).to have_http_status(:too_many_requests)
    end

    it "says when to come back" do
      31.times { upload }

      expect(response.headers['Retry-After']).to eq(3600.to_s)
      expect(response.body).to include('1 hour')
    end
  end

  describe "the refusal a client actually sees" do
    before { 31.times { upload } }

    it "is JSON for a JSON request" do
      post '/data.json', params: { gml: valid_gml, application: 'TestApp' }

      expect(response).to have_http_status(:too_many_requests)
      expect(response.parsed_body['error']).to include('Rate limit exceeded')
    end

    it "is plain text otherwise, not an HTML error page" do
      upload

      expect(response.content_type).to include('text/plain')
      expect(response.body).to include('Rate limit exceeded')
    end
  end

  describe "reads" do
    it "counts separately from uploads, so a blocked uploader can still read" do
      tag = FactoryBot.create(:tag)
      31.times { upload }

      get "/data/#{tag.id}.json"
      expect(response).to be_successful
    end
  end

  describe "alerting" do
    it "notifies once per trip so the subscriber can decide whether to mail" do
      events = []
      subscription = ActiveSupport::Notifications.subscribe('rate_limit.action_controller') do |event|
        events << event.payload
      end

      31.times { upload }
      ActiveSupport::Notifications.unsubscribe(subscription)

      expect(events.size).to eq(1)
      expect(events.first).to include(name: 'writes', to: 30)
    end
  end
end
