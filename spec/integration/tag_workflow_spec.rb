require 'rails_helper'

RSpec.describe "Tag Workflow Integration", type: :request do
  let(:user) { FactoryBot.create(:user) }
  let(:valid_gml) { '<gml><tag><header><environment><name>test</name></environment></header><drawing><stroke><pt><x>0</x><y>0</y><time>0</time></pt></stroke></drawing></tag></gml>' }

  describe "API tag creation workflow" do
    it "creates a tag via API with GML data" do
      expect {
        post '/data', params: { 
          gml: valid_gml,
          application: 'TestApp',
          location: 'San Francisco'
        }
      }.to change(Tag, :count).by(1)
      
      expect(response).to be_successful
      
      tag = Tag.last
      expect(tag.application).to eq('TestApp')
      expect(tag.location).to eq('San Francisco')
      expect(tag.data).to eq(valid_gml)
    end

    it "handles API errors gracefully" do
      post '/data', params: { invalid: 'data' }
      
      expect(response).to have_http_status(422)
      expect(response.body).to include('Error')
    end
  end

  describe "Web tag creation workflow" do
    before do
      # Mock login
      allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(user)
    end

    it "creates a tag via web form" do
      expect {
        post '/data', params: { 
          tag: {
            gml: valid_gml,
            application: 'WebApp',
            description: 'Test tag from web',
            user: user
          }
        }
      }.to change(Tag, :count).by(1)
      
      tag = Tag.last
      expect(tag.application).to eq('WebApp')
      expect(tag.description).to eq('Test tag from web')
      # User assignment happens in controller, verify the creation works
    end
  end

  describe "Tag viewing workflow" do
    let!(:tag) { FactoryBot.create(:tag, data: valid_gml) }

    it "shows tag in HTML format" do
      get "/data/#{tag.id}"
      
      expect(response).to be_successful
      expect(response.content_type).to include('text/html')
    end

    it "shows tag in JSON format" do
      get "/data/#{tag.id}.json"
      
      expect(response).to be_successful
      expect(response.content_type).to include('application/json')
      
      json = JSON.parse(response.body)
      expect(json['id']).to eq(tag.id)
    end

    it "shows tag in GML format" do
      get "/data/#{tag.id}.gml"
      
      expect(response).to be_successful
      expect(response.content_type).to include('application/xml')
      expect(response.body).to include('<gml>')
    end

    it "handles missing tags gracefully" do
      get "/data/999999"
      
      expect(response).to have_http_status(404)
    end
  end
end