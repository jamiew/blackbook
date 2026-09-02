class PasswordResetController < ApplicationController
  before_action :load_user_from_token, only: %i[edit update]
  before_action :require_no_user

  def new
    set_page_title 'Forgot your password?'
  end

  def edit
    set_page_title 'Resetting your password'
  end

  def create
    @user = User.find_by(email: params[:email])
    if @user.present?
      @user.deliver_password_reset_instructions!
      flash[:notice] = "Instructions to reset your password have been emailed to you. " \
                       "Please check your email."
      redirect_to root_url
    else
      flash[:error] = "No user was found with that email address"
      render action: :new
    end
  end

  def update
    credentials = params.expect(user: %i[password password_confirmation])

    # has_secure_password's validations are off, and `password=` ignores "" but
    # nils the digest for nil: without this a blank form reports success, and a
    # confirmation-only post locks the account out of bcrypt for good.
    if credentials[:password].blank?
      flash.now[:error] = "Password can't be blank"
      return render action: :edit
    end

    @user.password = credentials[:password]
    @user.password_confirmation = credentials[:password_confirmation]
    if @user.save
      flash[:notice] = "Password successfully updated"
      # Bare `user_path` fills :id from the current request, i.e. the reset
      # token, so it 404s and leaves the token in browser history.
      redirect_to(login_path)
    else
      render action: :edit
    end
  end

  private

  # Authlogic's perishable_token was a column that never expired. This token is
  # signed, expires in a day, and is invalidated by a password change.
  def load_user_from_token
    @user = User.find_by_token_for(:password_reset, params[:id])
    return unless @user.nil?

    flash[:notice] = "We're sorry, but we could not locate your account. " \
                     "If you are having issues try copying and pasting the URL " \
                     "from your email into your browser or restarting the " \
                     "reset password process."
    redirect_to(root_url)
  end
end
