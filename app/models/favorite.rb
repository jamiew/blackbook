class Favorite < ActiveRecord::Base
  belongs_to :object, :polymorphic => true
  belongs_to :user
  
  validates_associated :object, :on => :create
  validates_associated :user, :on => :create
  validates_uniqueness_of :user_id, :scope => [:object_id, :object_type], :on => :create, :message => "must be unique"
end