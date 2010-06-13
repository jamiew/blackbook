require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe TagsController do

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
        Tag.destroy_all # FIXME not sure why we're ending up w/ dupe objs
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
        pending 'TODO'
      end
    end
  end
end