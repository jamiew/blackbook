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

class Visualization < ActiveRecord::Base
    
  # supported application types; stored as an Array to maintain order pre-ruby 1.9
  # possibly rename to 'language'? Not sure. Little distinction atm
  KINDS = [
      ['',''], #Other/misc
      ['Flash','flash'],
      ['Javascript','javascript'],
      ['C++','cpp'],
      ['openFrameworks (C++)','openframeworks'],
      ['Processing','processing'],
      ['Ruby','ruby'],
      ['Python','python'],
      ['Java','java'],
      # Not sure what else we want -- probably don't need all of these just yet
    ]
    
  acts_as_commentable
  
  belongs_to :user
  
  validates_associated :user, :on => :create    
  validates_presence_of :name, :on => :create, :message => "can't be blank"
  validates_uniqueness_of :name, :on => :create, :message => "must be unique"
  # validates_presence_of :description, :on => :create, :message => "can't be blank"
  validates_presence_of :embed_url, :on => :create, :message => "can't be blank", :if => :is_embeddable
  # Optional: version, website, download (?), license (?)
  
  # Protect from mass assignment
  attr_protected :user_id, :slug

end
