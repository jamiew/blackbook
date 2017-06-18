require 'rails_helper'


describe UsersController do

  render_views

  describe "actions requiring no current user" do
    let!(:user){ FactoryGirl.create(:user) }

    it "should not redirect for a non-logged in user on :new" do
      get :new
      response.should_not be_redirect
    end

    it "should not redirect for a logged-out user on :create" do
      get :create
      response.should_not be_redirect
    end

    it "should redirect for a logged-in user on :new" do
      activate_authlogic
      UserSession.create(user)
      get :new
      response.should be_redirect
      flash[:error].should_not be_blank
    end

    it "should redirect for a logged-in user on :create" do
      activate_authlogic
      UserSession.create(user)
      get :create
      response.should be_redirect
      flash[:error].should_not be_blank
    end

    it "should redirect to account on successful :create" do
      resp = post :create, :user => {
        :login => 'bobby', :email => 'bob@example.com',
        :password => 'bobs_pass', :password_confirmation => 'bobs_pass'
      }
      found_user = User.find_by_login('bobby')
      found_user.should_not be_nil
      response.should redirect_to(user_path(:id => 'bobby'))
    end
  end

  describe "actions requiring a current user" do
    let!(:user){ FactoryGirl.create(:user) }

    before do
      activate_authlogic
      UserSession.create(user)
    end

    it "should work on :edit" do
      get :edit
      response.should render_template('users/edit')
    end

    it "should redirect back to settings page on :update" do
      post :update, user: { email: 'my@newemail.com' }
      response.should redirect_to(settings_path)
      flash[:notice].should be_present
    end

    it "should not redirect to account on failed :update" do
      post :update, :user => { :email => 'not_a_valid_email' }
      response.should_not be_redirect
      assigns(:user).errors.should be_present
      # flash[:error].should be_present
    end
  end

  describe '#show' do
    it 'works with user id' do
      @user = FactoryGirl.create(:user)
      get :show, id: @user.id
      response.should be_success
      assigns(:user).should == @user
    end

    it 'works with user login' do
      @user = FactoryGirl.create(:user, login: 'bobisok')
      get :show, id: 'bobisok'
      response.should be_success
      assigns(:user).should == @user
    end

    it 'returns 404 if user does not exist' do
      User.find_by_id(666).should be_nil
      lambda {
        get :show, id: 666
      }.should raise_error(ActiveRecord::RecordNotFound)
    end
  end
end
