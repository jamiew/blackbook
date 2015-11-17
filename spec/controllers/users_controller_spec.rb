require 'rails_helper'


describe UsersController do
  render_views

  before do
    @user = FactoryGirl.create(:user)
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
      activate_authlogic
      UserSession.create(@user)
      get :new
      response.should be_redirect
      flash[:error].should_not be_blank
    end

    it "should redirect for a logged in user on :create" do
      activate_authlogic
      UserSession.create(@user)
      get :create
      response.should be_redirect
      flash[:error].should_not be_blank
    end

    it "should redirect to account on successful :create" do
      resp = post :create, :user => { :login => 'bobby', :email => 'bob@example.com',
        :password => 'bobs_pass', :password_confirmation => 'bobs_pass' }
      found_user = User.find_by_login('bobby')
      found_user.should_not be_nil
      response.should redirect_to(user_path(:id => 'bobby'))
    end
  end

  describe "actions requiring a current user" do
    before do
      activate_authlogic
      UserSession.create(@user)
    end

    it "should redirect to login on :edit" do
      get :edit
      response.should render_template('users/edit')
    end

    it "should redirect back to settings page on :update" do
      get :update
      response.should redirect_to(settings_path)
    end

    it "should not redirect to account on failed :update" do
      post :update, :user => { :email => 'not_a_valid_email' }
      response.should_not be_redirect
    end
  end
end
