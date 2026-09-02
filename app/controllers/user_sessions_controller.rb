class UserSessionsController < ApplicationController
  before_action :require_no_user, only: %i[new create]
  before_action :require_user, only: :destroy

  def new
    set_page_title 'Login'
  end

  def create
    # The form posts flat fields. The nested user_session shape is what the old
    # Authlogic form sent, and any client still posting it keeps working.
    creds = params[:user_session] || params
    user = User.authenticate_by_credentials(creds[:login], creds[:password])

    if user
      log_in(user)
      flash[:notice] = "Login successful!"
      redirect_back_or_default(user_path(current_user))
    else
      # Deliberately vague: saying which of the two was wrong tells an attacker
      # whether an account exists.
      flash.now[:error] = "Failed to authenticate. Why don't you try that again?"
      render action: :new, status: :unauthorized
    end
  end

  def destroy
    log_out
    flash[:notice] = "Logout successful!"
    redirect_to(login_url)
  end
end
