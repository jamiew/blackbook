class Favorite < ActiveRecord::Base

  belongs_to :object, polymorphic: true
  belongs_to :user

  validates :object_id, presence: { message: "can't be blank" }, on: :create
  validates :object_type, presence: { message: "can't be blank" }, on: :create
  validates_associated :object, on: :create

  validates :user_id, presence: { message: "can't be blank" }, uniqueness: { scope: [:object_id, :object_type], message: "must be unique" }, on: :create
  validates_associated :user, on: :create

  after_create :create_notification

  scope :tags, -> { where('object_type = ?', 'Tag') }

protected

  def create_notification
    Notification.create(subject: self, verb: 'created', user: self.user)
  end

end
