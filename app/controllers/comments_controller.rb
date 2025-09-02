class CommentsController < ApplicationController
  before_action :require_user, only: %i[new create edit update destroy]
  before_action :setup

  def edit
    render plain: "TODO", status: 420
  end

  def create
    @comment = Comment.new(comment_parameters)
    @comment.user = current_user
    @comment.commentable = @commentable
    @comment.ip_address = request.remote_addr

    if @comment.save
      flash[:notice] = "Succesfully posted."
    else
      flash[:error] = "Failed to save your comment: #{@comment.errors.map(&:to_s)}"
      # TODO: should render the 'new' template
    end
    # redirect_back_or_default(url_for(@commentable))
    redirect_to(url_for(@commentable))
  end

  def update
    render plain: "TODO", status: 420
  end

  def destroy
    raise NoPermissionError unless is_admin? || @comment.user == current_user

    @comment.hidden_at = Time.zone.now
    @comment.save!
    flash[:notice] = "Comment deleted"
    redirect_back_or_default(comments_path(@commentable))
  end

  private

  def comment_parameters
    params.expect(comment: [:text])
  end

  protected

  def setup
    # Find a specific Comment objects
    @comment = Comment.find(params[:id]) if params[:id]

    # Found a foreign key for an object we happen to be commenting on
    if params[:tag_id]
      @commentable = Tag.find(params[:tag_id])
    elsif params[:user_id]
      @commentable = User.find_by(param: params[:user_id])
    else
      raise ActiveRecord::RecordNotFound, "A commentable (parent) object is required"
    end
  end
end
