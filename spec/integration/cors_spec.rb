require 'rails_helper'

# These live here rather than in a controller spec because Rack::Cors is
# middleware, and controller specs do not run the middleware stack.
RSpec.describe "CORS", type: :request do
  let(:origin) { 'https://someone-elses-site.example' }
  let(:tag) { FactoryBot.create(:tag) }
  let(:app_listing) { FactoryBot.create(:visualization) }

  describe "preflight" do
    it "answers OPTIONS without a route for it" do
      process :options, "/data/#{tag.id}.json", headers: {
        'HTTP_ORIGIN' => origin,
        'HTTP_ACCESS_CONTROL_REQUEST_METHOD' => 'GET'
      }

      expect(response).to have_http_status(:ok)
      expect(response.headers['Access-Control-Allow-Origin']).to eq('*')
      expect(response.headers['Access-Control-Allow-Methods']).to include('GET')
    end

    it "allows POST, so a browser uploader can read back the new tag id" do
      process :options, '/data', headers: {
        'HTTP_ORIGIN' => origin,
        'HTTP_ACCESS_CONTROL_REQUEST_METHOD' => 'POST'
      }

      expect(response).to have_http_status(:ok)
      expect(response.headers['Access-Control-Allow-Methods']).to include('POST')
    end
  end

  describe "actual requests" do
    # The whole point of the change: before this, only tags#show.json carried
    # a CORS header, so every other format was unreadable from a browser.
    {
      'tag index JSON' => ->(_t) { '/data.json' },
      'tag JSON' => ->(t) { "/data/#{t.id}.json" },
      'tag GML' => ->(t) { "/data/#{t.id}.gml" },
      'tag XML' => ->(t) { "/data/#{t.id}.xml" },
      'latest' => ->(_t) { '/latest.gml' },
      'random' => ->(_t) { '/random.gml' }
    }.each do |name, path|
      it "sets Access-Control-Allow-Origin on #{name}" do
        get path.call(tag), headers: { 'HTTP_ORIGIN' => origin }

        expect(response).to be_successful
        expect(response.headers['Access-Control-Allow-Origin']).to eq('*')
      end
    end

    it "sets Access-Control-Allow-Origin on an app listing" do
      get "/apps/#{app_listing.id}.json", headers: { 'HTTP_ORIGIN' => origin }

      expect(response).to be_successful
      expect(response.headers['Access-Control-Allow-Origin']).to eq('*')
    end

    it "lets a client revalidate a tag instead of refetching it" do
      get "/data/#{tag.id}.gml"
      etag = response.headers['ETag']

      get "/data/#{tag.id}.gml", headers: { 'HTTP_IF_NONE_MATCH' => etag }

      expect(response).to have_http_status(:not_modified)
      expect(response.body).to be_empty
    end

    it "refuses to let /random be cached, which would pin one tag for everybody" do
      tag # there has to be something to pick
      get '/random.gml'

      # Rack adds a weak ETag of its own, which is harmless: no-store forbids
      # storing the response at all. What matters is that it is never public.
      expect(response.headers['Cache-Control']).to include('no-store')
      expect(response.headers['Cache-Control']).not_to include('public')
    end

    # User has no attribute allowlist, and its columns include password digests,
    # salts and email addresses. CORS covers /users/* so the nested tag listing
    # works, which makes it worth pinning that the user record itself is not
    # serveable in any machine format.
    it "refuses to serve a user record as JSON or XML" do
      user = FactoryBot.create(:user)

      %w[json xml].each do |format|
        get "/users/#{user.to_param}.#{format}"

        expect(response).to have_http_status(:not_acceptable)
        expect(response.media_type).not_to include('json', 'xml')
      end
    end

    it "varies on Origin, so a shared cache cannot serve one origin's headers to another" do
      get "/data/#{tag.id}.json", headers: { 'HTTP_ORIGIN' => origin }

      expect(response.headers['Vary']).to include('Origin')
    end

    it "does not allow credentials, which would leak a logged-in session" do
      get "/data/#{tag.id}.json", headers: { 'HTTP_ORIGIN' => origin }

      expect(response.headers['Access-Control-Allow-Credentials']).to be_nil
    end
  end

  describe "JSONP, which CORS replaces but does not retire" do
    it "still wraps tags#show" do
      get "/data/#{tag.id}.json", params: { callback: 'load_gml' }

      expect(response.body).to start_with('/**/load_gml(')
    end

    # This was broken for years: callback: was passed to to_json, which ignores
    # it, instead of to render.
    it "wraps tags#validate" do
      post '/validate.json', params: { gml: tag.gml, callback: 'check' }

      expect(response.body).to start_with('/**/check(')
    end

    # Rails does not escape the callback before interpolating it into the body.
    it "drops a callback that is not a plain function name" do
      get "/data/#{tag.id}.json", params: { callback: '<script>alert(1)</script>' }

      expect(response.body).not_to include('<script>')
      expect(response.body).to start_with('{')
    end
  end
end
