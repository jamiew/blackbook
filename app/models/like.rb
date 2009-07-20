# == Schema Information
#
# Table name: likes
#
#  id          :integer(4)      not null, primary key
#  object_id   :integer(4)
#  object_type :string(255)
#  user_id     :integer(4)
#  created_at  :datetime
#  updated_at  :datetime
#

class Like < ActiveRecord::Base
  belongs_to :object, :polymorphic => true
  belongs_to :user
  
  validates_associated :object, :on => :create
  validates_associated :user, :on => :create
end
