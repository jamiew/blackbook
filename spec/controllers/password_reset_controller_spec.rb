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
      expect(response).to be_ok
      expect(response.body).to match(/Fill out the form below/)
      expect(response.body).to match(/form action=\"\/password_reset\"/)
    end
  end

  describe "POST #create" do
    it "should send an email to the user if found" do
      expect {
        post :create, email: @user.email
        expect(@user.perishable_token).not_to be_blank
        expect(response).to redirect_to(root_path)
      }.to change { ActionMailer::Base.deliveries.count }.by(1)
    end

    it "should re-render the new template given an invalid email" do
      post :create, email: 'jamie@notauser.com'
      expect(assigns[:user]).to be_nil
      expect(flash[:error]).not_to be_blank
      expect(response).to render_template('password_reset/new')
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
      expect(flash[:notice]).not_to be_blank
      expect(response).to redirect_to(user_path)
    end

    it "should not change password given a valid token and non-matching passwords" do
      @user.reset_perishable_token!
      expect {
        post :update, id: @user.perishable_token, user: {
          password: 'new_pass', password_confirmation: 'new' }
        @user.reload
      }.to_not change(@user, :crypted_password)
      expect(response).not_to be_redirect
    end

    it "should not change password given an invalid token" do
      expect {
        post :update, id: 'not_a_valid_token', user: {
          password: 'new_pass', password_confirmation: 'new' }
        expect(response).to redirect_to(root_url)
      }.to_not change(@user, :crypted_password)
    end

    it "should email the user that password was reset"

  end
end
