require 'rails_helper'


describe UsersController do

  render_views

  before do
    request.env["rack.url_scheme"] = "https"
    InvisibleCaptcha.timestamp_enabled = false
  end

  let(:valid_user_params){{
    user: {
      login: 'bobby',
      email: 'bob@example.com',
      password: 'bobs_pass',
      password_confirmation: 'bobs_pass'
    }
  }}

  describe "actions requiring no current user" do
    let!(:user){ FactoryBot.create(:user) }

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
  end

  # TODO refactor all above to be per-method...
  describe "POST #create" do
    it "works, creating a new, valid user record" do
      expect {
        post :create, valid_user_params
      }.to change(User, :count).by(1)
    end

    it "sets flash and redirects to profile page" do
      post :create, valid_user_params
      flash[:notice].should_not be_blank
      found_user = User.find_by_login(valid_user_params[:user][:login])
      found_user.should_not be_nil
      response.should redirect_to(user_path(id: valid_user_params[:user][:login]))
    end

    it "sends an email" do
      expect {
        post :create, valid_user_params
      }.to change { ActionMailer::Base.deliveries.count }.by(1)
    end
  end

  describe "actions requiring a current user" do
    let!(:user){ FactoryBot.create(:user) }

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
      post :update, user: { email: 'not_a_valid_email' }
      response.should_not be_redirect
      assigns(:user).errors.should be_present
      # flash[:error].should be_present
    end
  end

  describe '#show' do
    it 'works with user id' do
      @user = FactoryBot.create(:user)
      get :show, id: @user.id
      response.should be_success
      assigns(:user).should == @user
    end

    it 'works with user login' do
      @user = FactoryBot.create(:user, login: 'bobisok')
      get :show, id: 'bobisok'
      response.should be_success
      assigns(:user).should == @user
    end

    it 'works if you are logged-in' do
      activate_authlogic
      @user = FactoryBot.create(:user, login: 'bobisok')
      get :show, id: @user.login
      response.should be_success
    end

    it 'returns 404 if user does not exist' do
      User.find_by_id(666).should be_nil
      lambda {
        get :show, id: 666
      }.should raise_error(ActiveRecord::RecordNotFound)
    end
  end
end
