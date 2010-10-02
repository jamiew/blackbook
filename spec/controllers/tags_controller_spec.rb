require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe TagsController do

  integrate_views

  before do
    activate_authlogic
    @gml = Factory(:gml_object).data
  end

  describe "POST #create" do
    it "should create given params[:gml]" do
      post :create, :gml => @gml
      assigns[:tag].should be_valid
      response.should be_success
      response.body.should match(/\d+/)
    end

    it "should fail without params[:gml]" do
      post :create
      response.status.should == "422 Unprocessable Entity"
      response.body.should match(/Error/)
    end

    it "should create and assign to tempt1 given the correct secret" do
      pending 'TODO'
      @tag = Factory(:tag_from_tempt1)
      # ...
    end

    describe "redirection" do
      it "params[:redirect]=1 should redirect to the tag page" do
        Tag.destroy_all # FIXME not sure why we're ending up w/ dupe objs??
        post :create, :gml => @gml, :redirect => 1
        assigns[:tag].should be_valid
        response.should redirect_to(tag_path(assigns[:tag]))
      end

      it "params[:redirect_to]='http://google.com' should redirect there" do
        url = "http://google.com"
        post :create, :gml => @gml, :redirect_to => url
        response.should redirect_to(url)
      end

      it "params[:redirect_back]=1 should redirect to the HTTP_REFERER" do
        request.env['HTTP_REFERER'] = "http://fffff.at"
        post :create, :gml => @gml, :redirect_back => 1
        response.should redirect_to("http://fffff.at")
      end

    end

    describe "cache expiry" do
      it "should expire Home#index.html" do
        pending
        route = {:controller => 'home', :method => 'index'}
        # lambda { post :create, :gml => @gml }.should expire_fragment(route)
      end

      it "should expire Tags#index, all formats" do
        pending
      end

      it "should expire Tags#show, all formats" do
        pending
      end
    end
  end

  describe "GET #index" do
    before do
      @default_tag = Factory(:tag)
      @should_mention_application = lambda { |matchable|
        response.should be_success
        response.body.should match(matchable)
        # We're listing apps in a menu on the page so this always fails! d'oh!
        # response.body.should_not match(@default_tag.application)
      }
    end

    it "should filter on keywords" do
      Factory.create(:tag, :application => 'mfcc_test_app', :gml_keywords => 'mfcc')
      get :index, :keywords => 'mfcc'
      @should_mention_application.call(/mfcc_test_app/)
    end

    it "should filter on location" do
      Factory.create(:tag, :application => 'location_test', :location => 'San Francisco')
      get :index, :location => 'San Francisco'
      @should_mention_application.call(/location_test/)
    end

    it "should filter on application (using 'application')" do
      Factory.create(:tag, :application => 'app_test')
      get :index, :application => 'mfcc'
      # @should_mention_application.call(/app_test/)
    end

    it "should filter on application (using 'gml_application')" do
      Factory.create(:tag, :application => 'displayed_name', :gml_application => 'real_test_string')
      get :index, :application => 'real_test_string'
      # @should_mention_application.call(/displayed_name/)
    end

    it "should filter on user (using last 5 characters of gml_uniquekey_hash)" do
      tag = Factory.create(:tag, :application => 'user_test', :gml_uniquekey => 'lol')
      get :index, :user => tag.secret_username # TODO rename this method, it is undescriptive
      # @should_mention_application.call(/user_test/)
    end
  end

  describe "GET #show" do
    before do
      @tag = Factory(:tag)
    end

    it "HTML" do
      get :show, :id => @tag.to_param
      response.should be_success
      response.body.should match(/Tag ##{@tag.id}/)
    end

    it "GML" do
      get :show, :id => @tag.to_param, :format => 'gml'
      response.should be_success
      response.body.should match("<gml><tag><header>")
    end

    it "XML" do
      get :show, :id => @tag.to_param, :format => 'xml'
      response.should be_success
      response.body.should match("<id>")
    end

    describe "JSON" do
      it "should work" do
        get :show, :id => @tag.to_param, :format => 'json'
        response.should be_success
        response.body.should match("\"id\":#{@tag.id}")
      end

      it "should include GML data (GSON)" do
        get :show, :id => @tag.to_param, :format => 'json'
        response.body.should match("\"gml\":")
      end
    end
  end

  describe "GET #validate" do
    it "should work with an existing tag_id" do
      @tag = Factory(:tag)
      get :validate, :id => @tag.id
      response.should be_success
      response.body.should match(/Validating Tag ##{@tag.id}/)
    end

    it "should 404 with a bad tag_id" do
      Tag.destroy_all
      lambda { get :validate, :id => 666 }.should raise_error
      # TODO make sure it's a *404*
    end
  end

  describe "POST #validate" do
    it "should work given an existing tag_id (via tag[id])" do
      @tag = Factory(:tag)
      # FIXME why do we need to do "post :validate, :method => :post"? Cuz of the duplicate :get route?
      post :validate, :method => :post, :tag => {:id => @tag.id}
      response.should be_success
      response.body.should match(/Validating Tag ##{@tag.id}/)
    end

    it "should present form for submitting GML if no tag data" do
      post :validate, :method => :post
      response.should be_success
      response.body.should match(/GML Syntax Validator/)
    end

    it "should work with raw :tag data" do
      post :validate, :method => :post, :tag => {:gml => "<gml>...</gml>"}
      response.should be_success
      response.body.should match(/Validating Your Uploaded GML.../)
    end

    it "should return XML" do
      @tag = Factory(:tag)
      post :validate, :method => :post, :id => @tag.id, :format => 'xml'
      response.should be_success
      response.body.should match('<warnings>')
    end

    it "should return JSON" do
      @tag = Factory(:tag)
      post :validate, :method => :post, :id => @tag.id, :format => 'json'
      response.should be_success
      response.body.should match('"warnings":')
    end

    it "should return text" do
      @tag = Factory(:tag)
      post :validate, :method => :post, :id => @tag.id, :format => 'text'
      response.should be_success
      response.body.should match('warnings=')
    end

    it "should return text via XMLHttpRequest" do
      @tag = Factory(:tag)
      request.env['HTTP_X_REQUESTED_WITH'] = 'XMLHttpRequest'
      post :validate, :id => @tag.id
      response.should be_success
      response.body.should match('warnings=')
    end
  end
end