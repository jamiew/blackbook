require 'rails_helper'

RSpec.describe "Docs", type: :request do
  describe "GET /docs" do
    it "renders the index from docs/README.md" do
      get '/docs'

      expect(response).to be_successful
      expect(response.body).to include('000000book documentation')
    end

    it "rewrites relative .md links onto /docs so they do not 404" do
      get '/docs'

      expect(response.body).to include('href="/docs/api/downloading-gml"')
      # The "Edit on GitHub" link legitimately ends in .md, so only internal
      # hrefs are checked here.
      expect(response.body).not_to match(%r{href="(?!https?://)[^"]*\.md"})
    end
  end

  describe "GET /docs/*path" do
    it "renders a nested page" do
      get '/docs/api/uploading-gml'

      expect(response).to be_successful
      expect(response.body).to include('Uploading GML')
    end

    it "serves a directory as its README" do
      get '/docs/api'

      expect(response).to be_successful
      expect(response.body).to include('The 000000book API')
    end

    # The slug comes straight off the URL, so `..` must not reach the rest of
    # the app. config/master.key and credentials.yml.enc live two levels up.
    it "refuses to escape docs/" do
      ['/docs/../config/master.key', '/docs/../../etc/passwd',
       '/docs/../Gemfile', '/docs/%2e%2e/config/database'].each do |path|
        get path
        expect(response).to have_http_status(:not_found), "#{path} was served"
      end
    end

    it "404s an unknown page rather than raising" do
      get '/docs/nope'

      expect(response).to have_http_status(:not_found)
      expect(response.body).to include('No such page')
    end
  end

  describe "GET /api" do
    it "redirects to the API docs" do
      get '/api'

      expect(response).to redirect_to('/docs/api')
    end
  end

  describe "GET /llms.txt" do
    it "serves plain text listing every docs page" do
      get '/llms.txt'

      expect(response).to be_successful
      expect(response.media_type).to eq('text/plain')
      expect(response.body).to include('# 000000book', '/docs/api/downloading-gml')
    end
  end
end
