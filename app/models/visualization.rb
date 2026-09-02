class Visualization < ApplicationRecord
  # supported application types; stored as an Array to maintain order pre-ruby 1.9
  # possibly rename to 'language'? Not sure. Little distinction atm
  KINDS = [
    ['', ''], # Other/misc
    ['Flash', 'flash'],
    ['Javascript', 'javascript'],
    ['C++', 'cpp'],
    ['openFrameworks (C++)', 'openframeworks'],
    ['Processing', 'processing'],
    ['Ruby', 'ruby'],
    ['Python', 'python'],
    ['Java', 'java'],
    ['Other', 'other']
  ].freeze

  belongs_to :user, optional: true
  belongs_to :approver, class_name: 'User', foreign_key: :approved_by, optional: true

  validates :user_id, presence: { message: "can't be blank" }, on: :create
  validates_associated :user, on: :create
  validates :name, presence: { message: "can't be blank (and should be cool)" },
                   uniqueness: { message: "must be unique & that name already exists" }, on: :create
  validates :description, presence: { message: "can't be blank, what is this supposed to do?" }, on: :create
  validates :authors, presence: { message: "can't be blank, put your username if nothing else" }, on: :create
  # validates :website, presence: { message: "can't be blank" }, on: :create
  validates :embed_url, presence: { message: "can't be blank" }, on: :create, if: :is_embeddable
  validate :reject_if_any_html

  scope :approved, -> { where('approved_at < ?', Time.zone.now) }
  scope :pending, -> { where('approved_at IS NULL OR approved_at > ?', Time.zone.now) }

  after_create :create_notification

  has_one_attached :image do |attachable|
    attachable.variant :large,  resize_to_limit: [600, 600]
    attachable.variant :medium, resize_to_limit: [300, 300]
    attachable.variant :small,  resize_to_fill:  [100, 100]
    attachable.variant :tiny,   resize_to_fill:  [32, 32]
  end

  def default_image_url(style) = "/images/defaults/app_#{style}.jpg"
  # Rails 8 validates attachments directly, so the Paperclip-era :if guards on
  # image_file_name are gone. Backfilled images are exempt: some predate these
  # rules and would make otherwise valid records unsaveable.
  validate :image_is_a_supported_size_and_type, if: -> { image.attached? && image.changed_for_autosave? }

  SUPPORTED_IMAGE_TYPES = %w[image/jpeg image/pjpeg image/jpg image/gif image/png image/x-png].freeze
  MAX_IMAGE_SIZE = 1.megabyte

  def image_is_a_supported_size_and_type
    unless SUPPORTED_IMAGE_TYPES.include?(image.content_type)
      errors.add(:image, "Your thumbnail is not a valid image filetype (we accept JPG, PNG & GIF)")
    end

    return unless image.byte_size > MAX_IMAGE_SIZE

    errors.add(:image, 'Your thumbnail must be less than 1 megabyte (MB).')
  end

  def approved?
    approved_at && approved_at < Time.zone.now
  end

  protected

  def create_notification
    Notification.create(subject: self, verb: 'created', user: user)
  end

  def reject_if_any_html
    attributes.each do |key, value|
      # Rails.logger.warn "Visualization field #{key} contains HTML: #{value} -- objects=#{self.inspect}"
      errors.add(key, "is invalid") if value.present? && value.instance_of?(String) && value.match(/href=/)
    end
  end
end
