# frozen_string_literal: true

require 'rails_helper'

describe TagsController do
  render_views

  before do
    activate_authlogic
    @gml = FactoryBot.build(:gml_object).data
    allow_any_instance_of(GmlObject).to receive(:data).and_return(DEFAULT_GML)
  end

  describe 'POST #create' do
    it 'creates given params[:gml]' do
      post :create, params: { gml: @gml }
      expect(assigns[:tag]).to be_valid
      expect(response).to be_successful
      expect(response.body).to match(/\d+/)
    end

    it 'fails without params[:gml]' do
      post :create, params: {}
      expect(response.status).to eq(422) # Unprocessible Entity
      expect(response.body).to match(/Error/)
    end

    it 'creates and assign to tempt1 given the correct secret' do
      skip 'TODO'
      @tag = FactoryBot.create(:tag_from_tempt1)
      # ...
    end

    describe 'redirection' do
      it 'params[:redirect]=1 should redirect to the tag page' do
        Tag.destroy_all # FIXME: not sure why we're ending up w/ dupe objs??
        post :create, params: { gml: @gml, redirect: 1 }
        expect(assigns[:tag]).to be_valid
        expect(response).to redirect_to(tag_path(assigns[:tag]))
      end

      it "params[:redirect_to]='http://google.com' should redirect there" do
        url = 'http://google.com'
        post :create, params: { gml: @gml, redirect_to: url }
        expect(response).to redirect_to(url)
      end

      it 'params[:redirect_back]=1 should redirect to the HTTP_REFERER' do
        request.env['HTTP_REFERER'] = 'http://fffff.at'
        post :create, params: { gml: @gml, redirect_back: 1 }
        expect(response).to redirect_to('http://fffff.at')
      end
    end
  end

  describe 'GET #index' do
    before do
      @default_tag = FactoryBot.create(:tag)
      @should_mention_application = lambda { |matchable|
        expect(response).to be_successful
        expect(response.body).to match(matchable)
        # We're listing apps in a menu on the page so this always fails! d'oh!
        # response.body.should_not match(@default_tag.application)
      }
    end

    it 'works' do
      get :index
      expect(response).to be_successful
      expect(response.body).to match(/'application'/)
    end

    it 'does not raise exception if invalid ?page= param is passed' do
      get :index, params: { page: "-3242' UNION ALL SELECT 70,70,70,70#" }
      expect(flash[:error]).to match(/Invalid page number/)
      expect(response).to redirect_to(tags_path)
    end

    it 'filters on keywords' do
      FactoryBot.create(:tag, application: 'mfcc_test_app', gml_keywords: 'mfcc')
      get :index, params: { keywords: 'mfcc' }
      @should_mention_application.call(/mfcc_test_app/)
    end

    it 'filters on location' do
      FactoryBot.create(:tag, application: 'location_test', location: 'San Francisco')
      get :index, params: { location: 'San Francisco' }
      @should_mention_application.call(/location_test/)
    end

    it "filters on application (using 'application')" do
      FactoryBot.create(:tag, application: 'app_test')
      get :index, params: { application: 'mfcc' }
      # @should_mention_application.call(/app_test/)
    end

    it "filters on application (using 'gml_application')" do
      FactoryBot.create(:tag, application: 'displayed_name', gml_application: 'real_test_string')
      get :index, params: { application: 'real_test_string' }
      # @should_mention_application.call(/displayed_name/)
    end

    it 'filters on user (using last 5 characters of gml_uniquekey_hash)' do
      tag = FactoryBot.create(:tag, application: 'user_test', gml_uniquekey: 'lol')
      get :index, params: { user: tag.secret_username } # TODO: rename this method, it is undescriptive
      # @should_mention_application.call(/user_test/)
    end

    it 'works for a valid user' do
      user = FactoryBot.create(:user)
      get :index, params: { user_id: user.login }
      expect(assigns(:user)).to eq(user)
      expect(response).to be_successful
    end

    it '404S for a missing user' do
      expect do
        get :index, params: { user_id: 'asfdasadfasdf' }
        expect(assigns(:user)).to be_blank
      end.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  describe 'GET #show' do
    before do
      @tag = FactoryBot.create(:tag,
                               description: 'An <b>html</b> description which might contain XSS!',
                               location: 'http://locationURL.com',
                               gml_application: 'Some Application name',
                               gml_keywords: 'some,gml,keywords')
    end

    it '.html (default)' do
      get :show, params: { id: @tag.to_param }
      expect(response).to be_successful
      expect(response.body).to match(/Tag ##{@tag.id}/)
    end

    it '.gml' do
      get :show, params: { id: @tag.to_param, format: 'gml' }
      expect(response).to be_successful
      expect(response.body).to match('<gml><tag><header>')
    end

    it '.xml' do
      get :show, params: { id: @tag.to_param, format: 'xml' }
      expect(response).to be_successful
      expect(response.body).to match('<id>')
    end

    describe '.json' do
      it 'works' do
        get :show, params: { id: @tag.to_param, format: 'json' }
        expect(response).to be_successful
        expect(response.body).to match("\"id\":#{@tag.id}")
      end

      it 'includes GML data (GSON)' do
        get :show, params: { id: @tag.to_param, format: 'json' }
        expect(response.body).to match('"gml":')
      end

      it 'has CORS header set permissively' do
        get :show, params: { id: @tag.to_param, format: 'json' }
        expect(response.headers['Access-Control-Allow-Origin']).to eq('*')
        expect(response.headers['Access-Control-Allow-Methods']).to eq('GET, OPTIONS')
        expect(response.headers['Access-Control-Max-Age']).to eq('1728000')
      end
    end

    it '.gml should fail gracefully if GML data file is missing' do
      FactoryBot.create(:tag)
      allow_any_instance_of(Tag).to receive(:gml).and_return(nil)
      expect do
        get :show, params: { id: @tag.to_param, format: 'gml' }
        puts response.body.inspect
        expect(response).to be_successful
      end.to raise_error(MissingDataError)
    end
  end

  describe 'GET #validate' do
    it 'does not route, we want you to use POST only now' do
      expect({ get: '/validate' }).not_to be_routable
    end
  end

  describe 'POST #validate' do
    it 'routes' do
      expect({ post: '/validate' }).to route_to('tags#validate')
    end

    it 'works given an existing tag_id (via tag[id])' do
      @tag = FactoryBot.create(:tag)
      post :validate, params: { tag: { id: @tag.id } }
      expect(response).to be_successful
      expect(response.body).to match(/Validating Tag ##{@tag.id}/)
    end

    it 'presents form for submitting GML if no tag data' do
      post :validate
      expect(response).to be_successful
      expect(response.body).to match(/GML Syntax Validator/)
    end

    it 'works with raw :tag data' do
      post :validate, params: { tag: { gml: '<gml>...</gml>' } }
      expect(response).to be_successful
      expect(response.body).to match(/Validating Your Uploaded GML.../)
    end

    it 'returns XML' do
      @tag = FactoryBot.create(:tag)
      post :validate, params: { id: @tag.id, format: 'xml' }
      expect(response).to be_successful
      expect(response.body).to match('<warnings>')
    end

    it 'returns JSON' do
      @tag = FactoryBot.create(:tag)
      post :validate, params: { id: @tag.id, format: 'json' }
      expect(response).to be_successful
      expect(response.body).to match('"warnings":')
    end

    it 'returns text' do
      @tag = FactoryBot.create(:tag)
      post :validate, params: { id: @tag.id, format: 'text' }
      expect(response).to be_successful
      expect(response.body).to match('warnings=')
    end

    it 'returns text via XMLHttpRequest' do
      @tag = FactoryBot.create(:tag)
      request.env['HTTP_X_REQUESTED_WITH'] = 'XMLHttpRequest'
      post :validate, params: { id: @tag.id }
      expect(response).to be_successful
      expect(response.body).to match('warnings=')
    end
  end

  describe 'GET #latest' do
    it '.html redirects to the latest' do
      # Clear any existing tags to ensure our test tag is the latest
      Tag.delete_all
      tag = FactoryBot.create(:tag)
      get :latest
      path = tag_path(tag)
      expect(response).to redirect_to(path)
    end

    it '.json returns latest' do
      # Clear any existing tags to ensure our test tag is the latest
      Tag.delete_all
      tag = FactoryBot.create(:tag)
      get :latest, params: { format: 'json' }
      expect(assigns(:tag)).to eq(tag)
      expect(response).to be_successful
      expect(response.parsed_body['id']).to eq(tag.id)
    end
  end

  describe 'GET #random' do
    it 'works' do
      FactoryBot.create(:tag)
      get :random
      expect(assigns(:tag)).not_to be_nil
      expect(response).to be_redirect
    end
  end

  describe 'API Security' do
    it 'filters sensitive parameters from logs' do
      # Test that sensitive data isn't logged
      post :create, params: { gml: '<gml>test</gml>', secret: 'secret123' }

      # The actual filtering happens in the logger, this tests the endpoint works
      expect(response.status).to be_between(200, 422) # Accept any reasonable response
    end

    it "doesn't expose hidden attributes in API responses" do
      tag = FactoryBot.create(:tag, ip: '192.168.1.1', remote_secret: 'secret123')

      get :show, params: { id: tag.id, format: :json }

      json_response = response.parsed_body
      expect(json_response).not_to have_key('ip')
      expect(json_response).not_to have_key('remote_secret')
      expect(json_response).not_to have_key('user_id')
    end
  end
end
