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
      expect(response).not_to be_redirect
    end

    it "should not redirect for a logged-out user on :create" do
      get :create
      expect(response).not_to be_redirect
    end

    it "should redirect for a logged-in user on :new" do
      activate_authlogic
      UserSession.create(user)
      get :new
      expect(response).to be_redirect
      expect(flash[:error]).not_to be_blank
    end

    it "should redirect for a logged-in user on :create" do
      activate_authlogic
      UserSession.create(user)
      get :create
      expect(response).to be_redirect
      expect(flash[:error]).not_to be_blank
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
      expect(flash[:notice]).not_to be_blank
      found_user = User.find_by_login(valid_user_params[:user][:login])
      expect(found_user).not_to be_nil
      expect(response).to redirect_to(user_path(id: valid_user_params[:user][:login]))
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
      expect(response).to render_template('users/edit')
    end

    it "should redirect back to settings page on :update" do
      post :update, user: { email: 'my@newemail.com' }
      expect(response).to redirect_to(settings_path)
      expect(flash[:notice]).to be_present
    end

    it "should not redirect to account on failed :update" do
      post :update, user: { email: 'not_a_valid_email' }
      expect(response).not_to be_redirect
      expect(assigns(:user).errors).to be_present
      # flash[:error].should be_present
    end
  end

  describe '#show' do
    let(:default_user){ FactoryBot.create(:user) }
    it 'works with user id' do
      get :show, id: default_user.id
      expect(response).to be_success
      expect(assigns(:user)).to eq(default_user)
    end

    it 'works with user login' do
      expect(default_user.login).not_to eq(default_user.id)
      get :show, id: default_user.login
      expect(response).to be_success
      expect(assigns(:user)).to eq(default_user)
    end

    it 'works if you are logged-in' do
      activate_authlogic
      get :show, id: default_user.login
      expect(response).to be_success
    end

    it 'returns 404 if user does not exist' do
      expect(User.find_by_id(666)).to be_nil
      expect {
        get :show, id: 666
      }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it ".json does NOT work" do
      expect {
        get :show, id: default_user.to_param, format: :json
      }.to raise_error(ActionController::UnknownFormat)
    end

    it ".xml does NOT work" do
      expect {
        get :show, id: default_user.to_param, format: :xml
      }.to raise_error(ActionController::UnknownFormat)
    end

  end
end
