require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe UsersController do

  before(:each) do #:all?
    activate_authlogic
    @user = Factory.create(:user, :login => 'mmoen')
  end

  describe "actions requiring no current user" do
    it "should not redirect for a non-logged in user on :new" do
      get :new
      response.should_not be_redirect
    end

    it "should not redirect for a non-logged in user on :create" do
      get :create
      response.should_not be_redirect
    end

    it "should redirect for a logged in user on :new" do
      UserSession.create(@user)
      get :new
      response.should be_redirect
    end

    it "should redirect for a logged in user on :create" do
      UserSession.create(@user)
      get :create
      response.should be_redirect
    end

    it "should redirect to account on successful :create" do
      resp = post :create, :user => { :login => 'bob', :email => 'bob@example.com',
        :password => 'bobs_pass', :password_confirmation => 'bobs_pass' }
      STDERR.puts "RESP is #{resp.inspect}"
      found_user = User.find_by_login('bob')
      response.should redirect_to(user_path(found_user)) #TODO: requires has_slug...?
    end
  end

  describe "actions requiring a current user" do
    it "should redirect to login on :show" do
      get :show
      response.should redirect_to(login_path)
    end

    it "should redirect to login on :edit" do
      get :edit
      response.should redirect_to(login_path)
    end

    it "should redirect to settings page on :update" do
      get :update
      response.should redirect_to(settings_path)
    end

    it "should not redirect to login on :show" do
      UserSession.create(@user)
      get :show
      response.should_not be_redirect
    end

    it "should not redirect to login on :edit" do
      UserSession.create(@user)
      get :edit
      response.should_not be_redirect
    end

    it "should redirect to account on :update" do
      u = @user
      UserSession.create(u)
      post :update, :user => { :email => 'new_valid_email@example.com' }
      response.should redirect_to(user_path(u))
    end

    it "should not redirect to account on failed :update" do
      UserSession.create(@user)
      post :update, :user => { :email => 'not_a_valid_email' }
      response.should_not be_redirect
    end
  end
end
