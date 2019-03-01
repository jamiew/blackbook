class UserSessionsController < ApplicationController
  before_filter :require_no_user, only: [:new, :create]
  before_filter :require_user, only: :destroy

  def new
    @user_session = UserSession.new
  end

  def create
    sess = params['user_session'] || {}
    session_params = { login: sess['login'], password: sess['password'], remember_me: sess['remember_me'] }
    @user_session = UserSession.new(session_params)
    if @user_session.save
      flash[:notice] = "Login successful!"
      redirect_back_or_default(user_path(current_user))
    else
      flash[:error] = "Failed to authenticate. Why don't you try that again?"
      logger.debug @user_session.errors.inspect
      render action: :new, status: 401
    end
  end

  def destroy
    current_user_session.destroy
    flash[:notice] = "Logout successful!"
    redirect_back_or_default(login_url)
  end
end
