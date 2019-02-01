class Notification < ActiveRecord::Base

  scope :latest, -> { order('created_at DESC').limit(20) }

  validates_presence_of :subject_id, on: :create, message: "can't be blank"
  validates_presence_of :subject_type, on: :create, message: "can't be blank"
  validates_presence_of :verb, on: :create, message: "can't be blank"
  validates_associated :subject, on: :create
  validates_associated :user, on: :create

  belongs_to :subject, polymorphic: true
  belongs_to :user

end
