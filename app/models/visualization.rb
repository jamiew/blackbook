class Visualization < ActiveRecord::Base
  acts_as_commentable
  
  belongs_to :user
    
  validates_associated :user, :on => :create    
  validates_presence_of :name, :on => :create, :message => "can't be blank"
  validates_presence_of :description, :on => :create, :message => "can't be blank"
  
  # Optional: version, website, download (?), license (?)
  
  # Don't overwrite these from forms
  attr_protected :user_id, :slug
  
end

# == Schema Information
#
# Table name: visualizations
#
#  id          :integer(4)      not null, primary key
#  user_id     :integer(4)
#  name        :string(255)
#  slug        :string(255)
#  website     :string(255)
#  download    :string(255)
#  version     :string(255)
#  description :text
#

