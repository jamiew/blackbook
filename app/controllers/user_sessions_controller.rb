# frozen_string_literal: true

class UserSessionsController < ApplicationController
  before_action :require_no_user, only: %i[new create]
  before_action :require_user, only: :destroy

  def new
    set_page_title 'Login'
    @user_session = UserSession.new
  end

  def create
    sess = params['user_session'] || {}
    session_params = { login: sess['login'], password: sess['password'], remember_me: sess['remember_me'] }
    @user_session = UserSession.new(session_params)
    if @user_session.save
      flash[:notice] = 'Login successful!'
      redirect_back_or_default(user_path(current_user))
    else
      flash[:error] = "Failed to authenticate. Why don't you try that again?"
      logger.debug @user_session.errors.inspect
      render action: :new, status: :unauthorized
    end
  end

  def destroy
    current_user_session.destroy
    flash[:notice] = 'Logout successful!'
    redirect_back_or_default(login_url)
  end
end
