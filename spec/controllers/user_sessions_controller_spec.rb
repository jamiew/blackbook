# frozen_string_literal: true

require 'rails_helper'

describe UserSessionsController do
  render_views

  before do
    request.env['rack.url_scheme'] = 'https'
  end

  describe 'actions requiring no current user' do
    it 'does not redirect for a non-logged in user on :new' do
      get :new
      expect(response).not_to be_redirect
    end

    it 'does not redirect for a non-logged in user on :create' do
      get :create
      expect(response).not_to be_redirect
    end

    it 'redirects for a logged in user on :new' do
      activate_authlogic
      UserSession.create(FactoryBot.create(:user))
      get :new
      expect(response).to be_redirect
    end

    it 'redirects for a logged in user on :create' do
      activate_authlogic
      UserSession.create(FactoryBot.create(:user))
      get :create
      expect(response).to be_redirect
    end
  end

  describe 'actions requiring a current user' do
    it 'redirects to login on GET :destroy' do
      activate_authlogic
      UserSession.create(FactoryBot.create(:user))
      get :destroy
      expect(response).to redirect_to(login_path)
    end
  end

  describe 'POST :create' do
    let!(:username) { "jamiew_#{rand(100_000)}" }
    let!(:password) { 'password' }

    before do
      @user = FactoryBot.create(:user, login: username, password: password, password_confirmation: password)
    end

    it 'works and redirect to the account page' do
      user = User.find_by(login: username)
      expect(user).not_to be_nil # sanity-check our setup
      post :create, params: { user_session: { login: username, password: password } }
      expect(flash[:notice]).to match(/Login successful/)
      expect(current_user).to eq(@user)
      expect(response).to redirect_to(user_path(user))
    end

    it 'fails if credentials are missing' do
      post :create, params: { some_random_stuff: { login: nil } }
      expect(flash[:error]).to match(/Failed to authenticate/)
      expect(current_user).to be_nil
      expect(response).to be_unauthorized
    end

    it 'fails if credentials are incorrect' do
      post :create, params: { user_session: { login: username, password: 'idkman' } }
      expect(flash[:error]).to match(/Failed to authenticate/)
      expect(current_user).to be_nil
      expect(response).to be_unauthorized
    end
  end

  describe 'POST #destroy' do
    it 'works if logged-in' do
      activate_authlogic
      UserSession.create(FactoryBot.create(:user))
      post :destroy
      expect(flash[:notice]).to match(/Logout successful/)
      expect(current_user).to be_nil
      expect(response).to redirect_to(login_path)
    end

    it 'fails if logged-out' do
      expect(current_user).to be_nil # sanity-check
      post :destroy
      expect(flash[:error]).to match(/You must be logged in to do that/)
      expect(response).to redirect_to(login_path)
    end
  end
end
