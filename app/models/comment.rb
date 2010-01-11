# == Schema Information
#
# Table name: comments
#
#  id               :integer(4)      not null, primary key
#  title            :string(50)      default("")
#  comment          :text
#  commentable_id   :integer(4)
#  commentable_type :string(255)
#  user_id          :integer(4)
#  created_at       :datetime
#  updated_at       :datetime
#
# Indexes
#
#  index_comments_on_commentable_type  (commentable_type)
#  index_comments_on_commentable_id    (commentable_id)
#  index_comments_on_user_id           (user_id)
#

class Comment < ActiveRecord::Base

  belongs_to :commentable, :polymorphic => true
  belongs_to :user
  
  validates_presence_of :user_id, :on => :create, :message => "can't be blank"
  validates_associated :user, :on => :create
  validates_presence_of :comment, :on => :create, :message => "can't be blank"
  # TODO: validate not spam!
  
  named_scope :recent, {:order => "created_at DESC"}
  named_scope :limit, lambda {|limit| {:limit => limit}}
  
  
  
  # Helper class method to lookup all comments assigned to all commentable types for a given user.
  def self.find_comments_by_user(user)
    find(:all, :conditions => ["user_id = ?", user.id], :order => "created_at DESC")
  end

  # Helper class method to look up all comments for commentable class name and commentable id.
  def self.find_comments_for_commentable(commentable_str, commentable_id)
    find(:all, :conditions => ["commentable_type = ? and commentable_id = ?", commentable_str, commentable_id], :order => "created_at DESC")
  end

  # Helper class method to look up a commentable object given the commentable class name and id 
  def find_commentable(commentable_str, commentable_id)
    commentable_str.constantize.find(commentable_id)
  end

end
