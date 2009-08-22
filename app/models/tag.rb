# == Schema Information
#
# Table name: tags
#
#  id                 :integer(4)      not null, primary key
#  user_id            :integer(4)
#  title              :string(255)
#  slug               :string(255)
#  gml                :text
#  comment_count      :integer(4)
#  likes_count        :integer(4)
#  created_at         :datetime
#  updated_at         :datetime
#  location           :string(255)
#  application        :string(255)
#  set                :string(255)
#  cached_tag_list    :string(255)
#  image_file_name    :string(255)
#  image_content_type :string(255)
#  image_file_size    :integer(4)
#  image_updated_at   :datetime
#  uuid               :string(255)
#  ip                 :string(255)
#  description        :text
#
# Indexes
#
#  index_on_slug  (slug)
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
    # validates_attachment_presence :image
  
  after_create :create_notification
  
  def create_notification
    Notification.create(:subject => self, :verb => 'created')
  end
  
end
