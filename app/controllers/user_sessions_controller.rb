class UserSessionsController < ApplicationController
  before_filter :require_no_user, only: [:new, :create]
  before_filter :require_user, only: :destroy

  def new
    @user_session = UserSession.new
  end

  def create
    sess = params[:user_session]
    session_params = { login: sess.try(:login), password: sess.try(:password), remember_me: sess.try(:remember_me) }
    Rails.logger.debug session_params.inspect
    @user_session = UserSession.new(session_params)
    if @user_session.save
      flash[:notice] = "Login successful!"
      redirect_back_or_default(user_path(current_user))
    else
      flash[:error] = "Something bad happened. Why don't you try that again?"
      Rails.logger.debug @user_session.errors.inspect
      render action: :new
    end
  end

  def destroy
    current_user_session.destroy
    flash[:notice] = "Logout successful!"
    redirect_back_or_default(login_url)
  end
end
