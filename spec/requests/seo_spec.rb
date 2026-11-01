require 'rails_helper'

# What search engines, link previews and language-model agents read.
RSpec.describe 'search, social and agents' do
  before do
    @tag = FactoryBot.create(:tag)
    @app = FactoryBot.create(:visualization, approved_at: 1.hour.ago)
  end

  # One sweep over every page rather than five sweeps, so the list of pages
  # lives in one place.
  it 'gives every page a distinct title, a description, a canonical URL, a card and structured data' do # rubocop:disable RSpec/MultipleExpectations
    pages = ['/', '/data', "/data/#{@tag.id}", '/apps', "/apps/#{@app.id}", '/upload', '/about', '/users',
             '/docs', '/docs/api/downloading-gml', '/activity']
    titles = pages.map do |path|
      get path
      expect(response).to have_http_status(:ok), path
      body = response.body

      expect(body).to match(%r{<link href="http://www.example.com#{Regexp.escape(path)}" rel="canonical">}), path
      description = body[/content="([^"]+)" name="description"/, 1]
      expect(description.to_s.length).to be_between(50, 170), "#{path}: #{description.inspect}"
      expect(body).to match(%r{content="http://www.example.com/[^"]+" property="og:image"}), path
      expect(body).to match(/content="[^"]+" property="og:image:alt"/), path

      blocks = body.scan(%r{<script type="application/ld\+json">(.*?)</script>}m).flatten
      expect(blocks).not_to be_empty, path
      blocks.each { |json| expect(JSON.parse(json)).to include('@context' => 'https://schema.org') }

      body[%r{<title>([^<]+)</title>}, 1]
    end
    expect(titles.uniq.size).to eq(titles.size), titles.inspect
  end

  it 'describes the archive as a dataset, a tag as a work and an app as software' do
    get '/data'
    expect(response.body).to include('"@type":"Dataset"')
    get "/data/#{@tag.id}"
    expect(response.body).to include('"@type":"CreativeWork"').and include(".gml")
    get "/apps/#{@app.id}"
    expect(response.body).to include('"@type":"SoftwareApplication"')
  end

  it 'serves the docs as markdown for agents, and says so' do
    get '/docs/api/downloading-gml.md'
    expect(response.media_type).to eq('text/markdown')
    expect(response.body).to start_with('# Downloading GML')
    get '/docs.md'
    expect(response.media_type).to eq('text/markdown')

    get '/docs/api/downloading-gml'
    expect(response.headers['Link']).to include('/docs/api/downloading-gml.md>; rel="alternate"; type="text/markdown"')
    expect(response.body).to include('type="text/markdown"')
  end

  it 'has a web manifest, and an llms.txt that points at the markdown' do
    get '/manifest.json'
    expect(response).to have_http_status(:ok)
    expect(response.parsed_body['icons']).to be_present

    get '/llms.txt'
    expect(response.body).to include('.md').and include('preview=1')
  end
end
