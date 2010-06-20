class CommentsController < ApplicationController

  before_filter :require_user, :only => [:new, :create, :edit, :update, :destroy]
  before_filter :setup

  def index
    # Show all comments for given object
    # @commentable gets found in setup below
    raise "No commentable object means no comments" if @commentable.nil?
    @page, @per_page = params[:page] && params[:page].to_i || 1, 20
    @comments = @commentable.comments.sorted.paginate(:page => @page, :per_page => @per_page, :include => [:user, :commentable])
  end

  def show
    # Show a specific comment (via permalink?)
    render :partial => 'comments/comment', :object => @comment, :layout => true
  end

  def new 
    # Not used directly
    @comment = Comment.new
    render :text => "No juju here man.", :layout => true, :status => 420
  end

  def create

    #TODO: add some rudimentary rate limiting & IP banning

    @comment = Comment.new(params[:comment])
    @comment.user = current_user # Hard-assign (attr_protected)
    @comment.commentable = @commentable
    @comment.ip_address = request.remote_addr

    # redirect_back_or_default(url_for(@commentable))
    if @comment.save
      flash[:notice] = "Succesfully posted."
    else
      flash[:error] = "Failed to save your comment: #{@comment.errors.map(&:to_s)}"
    end
    redirect_to(url_for(@commentable)) #TODO: should behave differently for failure vs. success
  end

  def edit
    render :text => "TODO", :status => 420
  end

  def update
    render :text => "TODO", :status => 420
  end

  def destroy
    @comment.hidden_at = Time.now
    @comment.save!
    flash[:notice] = "Comment deleted"
  end

protected

  def setup
    # Find any specific Comment objects
    if params[:id]
      @comment = Comment.find(params[:id])
    end

    # Found a foreign key for an object we happen to be commenting on
    if params[:tag_id]
      @commentable = Tag.find(params[:tag_id])
    elsif params[:user_id]
      @commentable = User.find(params[:user_id])
    end
  end

end
