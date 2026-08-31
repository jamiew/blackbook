class Visualization < ApplicationRecord
  # Attributes the API publishes, in schema order.
  #
  # /apps/:id.json and .xml were never deliberately written. The controller
  # declares `respond_to :xml, :json`, no matching templates exist, and the
  # responders gem falls back to api_behavior, which dumped the whole record.
  # This pins the shape. Internal owner ids stay out, matching Tag.
  PUBLIC_ATTRIBUTES = %w[
    id approved_at authors created_at description download
    embed_callback embed_code embed_params embed_url
    image_content_type image_file_name image_file_size
    is_embeddable kind name slug updated_at version website
  ].freeze

  # Everything else, so that adding a column without deciding which list it
  # belongs in fails a spec. See spec/models/visualization_spec.rb.
  # Both are internal owner ids: who submitted it, and which admin approved it.
  PRIVATE_ATTRIBUTES = %w[user_id approved_by].freeze

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

  DEFAULT_IMAGE_STYLE = :medium
  def default_image_url(style = DEFAULT_IMAGE_STYLE) = "/images/defaults/app_#{style}.jpg"
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

  # Forced rather than left to the caller, so the responders fallback in
  # VisualizationsController cannot publish a column nobody meant to publish.
  def as_json(opts = {}) = super(opts.merge(only: PUBLIC_ATTRIBUTES))

  # Built from attributes like Tag#to_xml, not from super: Rails 8 dropped
  # ActiveModel::Serializers::Xml, so ActiveRecord has no to_xml to call. That
  # is also why /apps/:id.xml was raising before this existed.
  def to_xml(opts = {}) = attributes.slice(*PUBLIC_ATTRIBUTES).to_xml(opts)

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
