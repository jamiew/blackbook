require 'rails_helper'

describe CommentsController do
  render_views

  before do
    activate_authlogic
    @tag = FactoryBot.create(:tag)
  end

  it "POST #create should work" do
    pending 'comments disabled'
    login_as_user
    post :create, tag_id: @tag.id, comment: {text: 'Lolcats R awesome'}
  end

  describe "DELETE#destroy" do
    before do
      @comment = FactoryBot.create(:comment)
    end

    it "should work for admins" do
      pending 'comments disabled'
      login_as_admin
      delete :destroy, tag_id: @tag.id, id: @comment.id
      Comment.find(@comment.id).hidden?.should == true
      response.should be_redirect
    end

    it "should work for the comment owner" do
      pending 'comments disabled'
      login_as_user(@comment.user)
      delete :destroy, tag_id: @tag.id, id: @comment.id
      Comment.find(@comment.id).hidden?.should == true
      response.should be_redirect
    end

    it "should fail for non-owner users" do
      pending 'comments disabled'
      login_as_user
      delete :destroy, tag_id: @tag.id, id: @comment.id
      response.status.should == 403 # Forbidden
    end

    it "should fail for logged-out users" do
      pending 'comments disabled'
      delete :destroy, tag_id: @tag.id, id: @comment.id
      response.status.should == 403 # Forbidden
    end
  end

end
