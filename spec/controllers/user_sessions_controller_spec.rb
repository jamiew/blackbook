require 'rails_helper'


describe UserSessionsController do
  render_views

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
      activate_authlogic
      UserSession.create(FactoryBot.create(:user))
      get :new
      response.should be_redirect
    end

    it "should redirect for a logged in user on :create" do
      activate_authlogic
      UserSession.create(FactoryBot.create(:user))
      get :create
      response.should be_redirect
    end
  end

  describe "actions requiring a current user" do
    it "should redirect to login on GET :destroy" do
      activate_authlogic
      UserSession.create(FactoryBot.create(:user))
      get :destroy
      response.should redirect_to(login_path)
    end
  end

  describe "POST :create" do
    let!(:username) { 'jamiew' }
    let!(:password) { 'password' }

    before do
      @user = FactoryBot.create(:user, login: username, password: password, password_confirmation: password)
    end

    it "should work and redirect to the account page" do
      user = User.find_by_login(username)
      user.should_not be_nil # sanity-check our setup
      post :create, user_session: { login: username, password: password }
      flash[:notice].should match(/Login successful/)
      current_user.should == @user
      response.should redirect_to(user_path(user))
    end

    it "should fail if credentials are missing" do
      post :create, some_random_stuff: { login: nil }
      flash[:error].should match(/Failed to authenticate/)
      current_user.should be_nil
      response.should be_unauthorized
    end

    it "should fail if credentials are incorrect" do
      post :create, user_session: { login: username, password: 'idkman' }
      flash[:error].should match(/Failed to authenticate/)
      current_user.should be_nil
      response.should be_unauthorized
    end
  end

  describe "POST #destroy" do
    it "should work if logged-in" do
      activate_authlogic
      UserSession.create(FactoryBot.create(:user))
      post :destroy
      flash[:notice].should  match(/Logout successful/)
      current_user.should be_nil
      response.should redirect_to(login_path)
    end

    it "should fail if logged-out" do
      current_user.should be_nil # sanity-check
      post :destroy
      flash[:error].should match(/You must be logged in to do that/)
      response.should redirect_to(login_path)
    end
  end
end
