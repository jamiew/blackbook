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
      it "should expire the index page" do
        pending
      end

      # TODO there are a # of other keys expired to test!!
    end
  end

  describe "GET #index" do
    before do
      @default_tag = Factory(:tag)
      @should_mention_application = lambda { |matchable|
        response.should be_success
        response.body.should match(matchable)
        response.body.should_not match(@default_tag.application)
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
    it "should present form for submitting GML if no tag data" do
      pending 'route broken?'
      post :validate
      response.should be_success
      response.body.should match(/GML Syntax Validator/)
    end

    it "should work with raw :tag data" do
      pending 'route broken?'
      post :validate, :tag => {:gml => "<gml>...</gml>"}
      response.should be_success
      response.body.should match(/Validating Your GML.../)
    end

    it "should return XML" do
      pending 'route broken'
      @tag = Factory(:tag)
      post :validate, :id => @tag.id, :format => 'xml'
      response.should be_success
      # TODO test syntax
    end

    it "should return JSON" do
      @tag = Factory(:tag)
      post :validate, :id => @tag.id, :format => 'json'
      response.should be_success
      # TODO test syntax
    end

    it "should return text via XmlHttpRequest" do
      pending 'broken too :('
      @tag = Factory(:tag)
      xhr :validate, :id => @tag.id, :format => 'json'
      response.should be_success
      # TODO test syntax
    end
  end
end