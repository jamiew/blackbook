class Comment < ActiveRecord::Base

  belongs_to :commentable, polymorphic: true
  belongs_to :user

  validates_presence_of :commentable_id, on: :create, message: "can't be blank"
  validates_presence_of :commentable_type, on: :create, message: "can't be blank"
  validates_associated  :commentable, on: :create
  validates_presence_of :user_id, on: :create, message: "can't be blank"
  validates_associated  :user, on: :create
  validates_presence_of :text, on: :create, message: "can't be blank"

  attr_protected :user_id, :commentable_type, :commentable_type, :ip_address

  scope :sorted, -> { order("created_at DESC") }
  scope :visible, -> { where('hidden_at IS NULL OR hidden_at > ?', Time.now) }
  scope :hidden, -> { where('hidden_at < ?', Time.now) }

  # before_save :denormalize_user_fields
  after_create :create_notification

  def hidden?
    !hidden_at.blank?
  end

  # Helper class method to lookup all comments assigned to all commentable types for a given user.
  def self.find_comments_by_user(user)
    find(:all, conditions: ["user_id = ?", user.id], order: "created_at DESC")
  end

  # Helper class method to look up all comments for commentable class name and commentable id.
  def self.find_comments_for_commentable(commentable_str, commentable_id)
    find(:all, conditions: ["commentable_type = ? and commentable_id = ?", commentable_str, commentable_id], order: "created_at DESC")
  end

  # Helper class method to look up a commentable object given the commentable class name and id
  def find_commentable(commentable_str, commentable_id)
    commentable_str.constantize.find(commentable_id)
  end

protected

  # possible breakage -- this will need to be bulk updated if we ever change the way users' URLs are generated
  # wish there was a way to couple these kinds of things better. Caching user_url not REQUIRED, it'll just be much cleaner...
  def denormalize_user_fields
    self.cached_user_login = user.login if self.respond_to?(:cached_user_login=)
    self.cached_user_url = user_path(user)  if self.respond_to?(:cached_user_url=)
    # Note) Also need thumbnail if we're going to do this. Not using it right now.
  end

  def create_notification
    Notification.create(subject: self, verb: 'created', user: self.user)
  end

end
