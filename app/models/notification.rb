class Notification < ApplicationRecord
  # Comment notifications survive the removal of their model and table.
  # Filter before preloading subjects so those rows cannot break the page.
  SUBJECT_TYPES = %w[Tag User Visualization Favorite].freeze

  scope :displayable, -> { where(subject_type: SUBJECT_TYPES) }
  scope :latest, -> { order(created_at: :desc).limit(20) }

  validates :subject_id, presence: { message: "can't be blank" }, on: :create
  validates :subject_type, presence: { message: "can't be blank" }, on: :create
  validates :verb, presence: { message: "can't be blank" }, on: :create
  validates_associated :subject, on: :create
  validates_associated :user, on: :create

  belongs_to :subject, polymorphic: true, optional: true
  belongs_to :user, optional: true
end
