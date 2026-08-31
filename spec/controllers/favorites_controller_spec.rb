require 'rails_helper'

describe FavoritesController do
  render_views

  before do
    @user = FactoryBot.create(:user)
    @tag = FactoryBot.create(:tag)
  end

  describe "GET#index" do
    it "sends anonymous visitors to login rather than blowing up" do
      logout
      get :index
      expect(response).to redirect_to(login_path)
      expect(flash[:error]).to include('logged in')
    end

    it "works with no user_id" do
      login_as_user(@user)
      get :index
      expect(response).to be_successful
      expect(assigns(:user)).to eq(current_user)
    end

    it "works with user_id but ignore it" do
      login_as_user(@user)
      get :index, params: { user_id: @user.id }
      expect(response).to be_successful
      expect(assigns(:user)).to eq(current_user)
    end
  end

  describe "POST #create" do
    before do
      @user = FactoryBot.create(:user)
      request.env["HTTP_REFERER"] = tag_path(@tag)
      # FIXME: we're relying on redirect_to(:back) inside FavoritesController...
    end

    it "fails if not logged-in" do
      logout
      post :create, params: { tag_id: @tag.id }
      expect(response).not_to be_successful
      expect(flash[:error]).not_to be_blank
    end

    it "redirects and flashes a notice when logged in" do
      login_as_user(@user)
      post :create, params: { tag_id: @tag.id }
      expect(response).to be_redirect
      expect(flash[:notice]).not_to be_blank
    end

    it "1st time should create a favorite" do
      login_as_user(@user)
      expect { post :create, params: { tag_id: @tag.id } }.to change(@user.favorites, :count).by(1)
      expect(flash[:notice]).not_to be_blank
    end

    it "2nd time should delete the favorite (unfavorite)" do
      login_as_user(@user)
      expect do
        post :create, params: { tag_id: @tag.id }
        post :create, params: { tag_id: @tag.id }
      end.not_to change(@user.favorites, :count)
      expect(flash[:notice]).not_to be_blank
    end
  end
end
