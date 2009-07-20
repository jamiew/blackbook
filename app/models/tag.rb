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
  
  belongs_to :user
  has_many :comments
  has_many :likes
  
  validates_associated :user, :on => :create
  
  has_attached_file :image, :styles => { :web => '800x800>', :small => "300x300>", :thumb => "100x100>" }
end
