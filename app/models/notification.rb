class Notification < ActiveRecord::Base

  scope :latest, -> { order('created_at DESC').limit(20) }

  validates :subject_id, presence: { message: "can't be blank" }, on: :create
  validates :subject_type, presence: { message: "can't be blank" }, on: :create
  validates :verb, presence: { message: "can't be blank" }, on: :create
  validates_associated :subject, on: :create
  validates_associated :user, on: :create

  belongs_to :subject, polymorphic: true, optional: true
  belongs_to :user, optional: true

end
