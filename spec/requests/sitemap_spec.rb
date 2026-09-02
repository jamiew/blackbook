require 'rails_helper'

RSpec.describe 'sitemap.xml' do
  it 'lists the pages, the docs, the apps and the newest tags' do
    app = FactoryBot.create(:visualization, approved_at: 1.hour.ago)
    tag = FactoryBot.create(:tag)

    get '/sitemap.xml'

    expect(response).to have_http_status(:ok)
    expect(response.media_type).to eq('application/xml')
    expect(response.body).to include('/about').and include('/docs/api/downloading-gml')
    expect(response.body).to include("/apps/#{app.id}").and include("/data/#{tag.id}")
    expect(response.headers['Cache-Control']).to include('public')
  end
end
