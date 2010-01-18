require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe Admin::BaseController do

  before(:each) do
    activate_authlogic
  end

  it "should require an admin user" do
    UserSession.create(Factory.create(:admin))
    get :index
    response.should be_success
  end

  it "should redirect to login for no user or non-admin user" do
    STDERR.puts "Trying to get :index w/ allegedly no user... current_user=#{current_user.inspect}"
    get :index
    response.should redirect_to(login_path)

    UserSession.create(Factory.create(:user))
    get :index
    response.should redirect_to(login_path)
  end
end
