require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe Admin::BaseController do

  before(:each) do
    activate_authlogic
  end

  it "should require an admin user" do
    UserSession.create(Factory(:admin))
    get :index
    response.should be_success
  end

  it "should redirect to login for no user" do
    get :index
    response.should redirect_to(login_url)
  end

  it "should redirect to the root for a non-admin user" do
    UserSession.create(Factory(:user))
    get :index
    response.should redirect_to(root_url)
  end
end
