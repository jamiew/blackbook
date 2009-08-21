# == Schema Information
#
# Table name: tags
#
#  id            :integer(4)      not null, primary key
#  user_id       :integer(4)
#  title         :string(255)
#  slug          :string(255)
#  description   :text
#  comment_count :integer(4)
#  likes_count   :integer(4)
#  created_at    :datetime
#  updated_at    :datetime
#

class Tag < ActiveRecord::Base

  acts_as_commentable
  # is_taggable :tags
  # has_many :comments  
  
  belongs_to :user
  # has_many :comments
  has_many :likes
  
  validates_associated :user, :on => :create
  
  has_attached_file :image, 
    :default_style => :medium, 
    :styles => { :large => '600x600>', :medium => "300x300>", :small => '100x100#', :tiny => "32x32#" }
  validates_attachment_presence :image
  
  after_create :create_notification
  
  def create_notification
    Notification.create(:subject => self, :verb => 'created')
  end
  
end
