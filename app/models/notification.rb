class Notification < ActiveRecord::Base
  
  named_scope :latest, :order => 'created_at DESC', :limit => 20
  
  validates_associated :attribute, :on => :create
  
end
