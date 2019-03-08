require 'rails_helper'


describe PasswordResetController do
  render_views

  before do
    request.env["rack.url_scheme"] = "https"
    # activate_authlogic
    @user = FactoryBot.create(:user)
  end

  describe "GET #new" do
    it "should render a form input field correctly" do
      get :new
      response.should be_ok
      response.body.should match(/Fill out the form below/)
      response.body.should match(/form action=\"\/password_reset\"/)
    end
  end

  describe "POST #create" do
    it "should send an email to the user if found" do
      expect {
        post :create, email: @user.email
        @user.perishable_token.should_not be_blank
        response.should redirect_to(root_path)
      }.to change { ActionMailer::Base.deliveries.count }.by(1)
    end

    it "should re-render the new template given an invalid email" do
      post :create, email: 'jamie@notauser.com'
      assigns[:user].should be_nil
      flash[:error].should_not be_blank
      response.should render_template('password_reset/new')
    end
  end

  describe "POST #update" do
    it "should change password given a valid token and matching passwords" do
      @user.reset_perishable_token!
      expect {
        post :update, id: @user.perishable_token, user: {
          password: 'totally_fresh!', password_confirmation: 'totally_fresh!' }
        @user.reload
      }.to change(@user, :crypted_password)
      flash[:notice].should_not be_blank
      response.should redirect_to(user_path)
    end

    it "should not change password given a valid token and non-matching passwords" do
      @user.reset_perishable_token!
      expect {
        post :update, id: @user.perishable_token, user: {
          password: 'new_pass', password_confirmation: 'new' }
        @user.reload
      }.to_not change(@user, :crypted_password)
      response.should_not be_redirect
    end

    it "should not change password given an invalid token" do
      expect {
        post :update, id: 'not_a_valid_token', user: {
          password: 'new_pass', password_confirmation: 'new' }
        response.should redirect_to(root_url)
      }.to_not change(@user, :crypted_password)
    end

    it "should email the user that password was reset"

  end
end
