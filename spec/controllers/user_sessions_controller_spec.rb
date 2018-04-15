require 'rails_helper'


describe UserSessionsController do
  render_views

  before do
    activate_authlogic
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
      UserSession.create(FactoryBot.create(:user))
      get :new
      response.should be_redirect
    end

    it "should redirect for a logged in user on :create" do
      UserSession.create(FactoryBot.create(:user))
      get :create
      response.should be_redirect
    end
  end

  describe "actions requiring a current user" do
    it "should redirect to login on :destroy" do
      get :destroy
      response.should redirect_to(login_path)
    end
  end

  describe "session management" do
    it "should redirect to the account page on successful login" do
      FactoryBot.create(:user, :login => 'jamiew', :password => 'password', :password_confirmation => 'password')
      post :create, :user_session => { :login => 'jamiew', :password => 'password' }
      user = User.find_by_login('jamiew')
      response.should redirect_to(user_path(user))
    end

    it "should redirect to the login page on session deletion" do
      UserSession.create(FactoryBot.create(:user))
      post :destroy
      response.should redirect_to(login_path)
    end
  end
end
