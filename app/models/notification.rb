# == Schema Information
#
# Table name: notifications
#
#  id              :integer(4)      not null, primary key
#  subject_id      :string(255)
#  subject_type    :string(255)
#  verb            :string(255)
#  user_id         :integer(4)
#  supplement_id   :integer(4)
#  supplement_type :string(255)
#  created_at      :datetime
#  updated_at      :datetime
#

class Notification < ActiveRecord::Base
  
  named_scope :latest, :order => 'created_at DESC', :limit => 20
  
  validates_associated :subject, :on => :create
  validates_presence_of :verb, :on => :create, :message => "can't be blank"
  validates_associated :user, :on => :create
  
end
