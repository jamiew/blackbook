# frozen_string_literal: true

class Comment < ApplicationRecord
  belongs_to :commentable, polymorphic: true
  belongs_to :user

  validates :commentable_id, presence: { message: "can't be blank" }, on: :create
  validates :commentable_type, presence: { message: "can't be blank" }, on: :create
  validates_associated :commentable, on: :create
  validates :user_id, presence: { message: "can't be blank" }, on: :create
  validates_associated :user, on: :create
  validates :text, presence: { message: "can't be blank" }, on: :create

  scope :sorted, -> { order(created_at: :desc) }
  scope :visible, -> { where('hidden_at IS NULL OR hidden_at > ?', Time.zone.now) }
  scope :hidden, -> { where(hidden_at: ...Time.zone.now) }

  # before_save :denormalize_user_fields
  after_create :create_notification

  def hidden?
    hidden_at.present?
  end

  # Helper class method to lookup all comments assigned to all commentable types for a given user.
  def self.find_comments_by_user(user)
    where(user_id: user.id).order(created_at: :desc)
  end

  # Helper class method to look up all comments for commentable class name and commentable id.
  def self.find_comments_for_commentable(commentable_str, commentable_id)
    where(commentable_type: commentable_str, commentable_id: commentable_id).order(created_at: :desc)
  end

  # Helper class method to look up a commentable object given the commentable class name and id
  def find_commentable(commentable_str, commentable_id)
    commentable_str.constantize.find(commentable_id)
  end

  protected

  # possible breakage -- this will need to be bulk updated if we ever change the way users' URLs are generated
  # wish there was a way to couple these kinds of things better. Caching user_url not REQUIRED, it'll just be much cleaner...
  def denormalize_user_fields
    self.cached_user_login = user.login if respond_to?(:cached_user_login=)
    self.cached_user_url = user_path(user) if respond_to?(:cached_user_url=)
    # Note) Also need thumbnail if we're going to do this. Not using it right now.
  end

  def create_notification
    Notification.create(subject: self, verb: 'created', user: user)
  end
end
