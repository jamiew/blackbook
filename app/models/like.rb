class Like < ActiveRecord::Base
  belongs_to :object, :polymorphic => true
  belongs_to :user
  
  validates_associated :object, :on => :create
  validates_associated :user, :on => :create
end
