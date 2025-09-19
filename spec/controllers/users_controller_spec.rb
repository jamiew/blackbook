# frozen_string_literal: true

require 'rails_helper'

describe UsersController do
  render_views

  before do
    request.env['rack.url_scheme'] = 'https'
    InvisibleCaptcha.timestamp_enabled = false
  end

  let(:valid_user_params) do
    {
      user: {
        login: 'bobby',
        email: 'bob@example.com',
        password: 'bobs_pass',
        password_confirmation: 'bobs_pass'
      }
    }
  end

  describe 'actions requiring no current user' do
    let!(:user) { FactoryBot.create(:user) }

    it 'does not redirect for a non-logged in user on :new' do
      pending 'USER SIGNUPS DISABLED'
      get :new
      expect(response).not_to be_redirect
    end

    it 'does not redirect for a logged-out user on :create' do
      pending 'USER SIGNUPS DISABLED'
      get :create
      expect(response).not_to be_redirect
    end

    it 'redirects for a logged-in user on :new' do
      activate_authlogic
      UserSession.create(user)
      get :new
      expect(response).to be_redirect
      expect(flash[:error]).not_to be_blank
    end

    it 'redirects for a logged-in user on :create' do
      pending 'USER SIGNUPS DISABLED'
      activate_authlogic
      UserSession.create(user)
      get :create
      expect(response).to be_redirect
      expect(flash[:error]).not_to be_blank
    end
  end

  # TODO: refactor all above to be per-method...
  describe 'POST #create' do
    it 'works, creating a new, valid user record' do
      pending 'USER SIGNUPS DISABLED'
      expect do
        post :create, params: valid_user_params
      end.to change(User, :count).by(1)
    end

    it 'sets flash and redirects to profile page' do
      pending 'USER SIGNUPS DISABLED'
      post :create, params: valid_user_params
      expect(flash[:notice]).not_to be_blank
      found_user = User.find_by(login: valid_user_params[:user][:login])
      expect(found_user).not_to be_nil
      expect(response).to redirect_to(user_path(id: valid_user_params[:user][:login]))
    end

    it 'sends an email' do
      pending 'USER SIGNUPS DISABLED'
      expect do
        post :create, params: valid_user_params
      end.to change { ActionMailer::Base.deliveries.count }.by(1)
    end
  end

  describe 'actions requiring a current user' do
    let!(:user) { FactoryBot.create(:user) }

    before do
      activate_authlogic
      UserSession.create(user)
    end

    it 'works on :edit' do
      get :edit
      expect(response).to render_template('users/edit')
    end

    it 'redirects back to settings page on :update' do
      pending 'USER SIGNUPS DISABLED'
      post :update, params: { user: { email: 'my@newemail.com' } }
      expect(response).to redirect_to(settings_path)
      expect(flash[:notice]).to be_present
    end

    it 'does not redirect to account on failed :update' do
      pending 'USER SIGNUPS DISABLED'
      post :update, params: { user: { email: 'not_a_valid_email' } }
      expect(response).not_to be_redirect
      expect(assigns(:user).errors).to be_present
      # flash[:error].should be_present
    end
  end

  describe '#show' do
    let(:default_user) { FactoryBot.create(:user) }

    it 'works with user id' do
      get :show, params: { id: default_user.id }
      expect(response).to be_successful
      expect(assigns(:user)).to eq(default_user)
    end

    it 'works with user login' do
      expect(default_user.login).not_to eq(default_user.id)
      get :show, params: { id: default_user.login }
      expect(response).to be_successful
      expect(assigns(:user)).to eq(default_user)
    end

    it 'works if you are logged-in' do
      activate_authlogic
      get :show, params: { id: default_user.login }
      expect(response).to be_successful
    end

    it 'returns 404 if user does not exist' do
      expect(User.find_by(id: 666)).to be_nil
      expect do
        get :show, params: { id: 666 }
      end.to raise_error(ActiveRecord::RecordNotFound)
    end

    it '.json does NOT work' do
      expect do
        get :show, params: { id: default_user.to_param, format: :json }
      end.to raise_error(ActionController::UnknownFormat)
    end

    it '.xml does NOT work' do
      expect do
        get :show, params: { id: default_user.to_param, format: :xml }
      end.to raise_error(ActionController::UnknownFormat)
    end
  end
end
