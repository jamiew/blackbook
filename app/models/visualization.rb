# frozen_string_literal: true

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
  has_many :comments, as: :commentable
  belongs_to :approver, class_name: 'User', foreign_key: :approved_by, optional: true

  validates :user_id, presence: { message: "can't be blank" }, on: :create
  validates_associated :user, on: :create
  validates :name, presence: { message: "can't be blank (and should be cool)" },
                   uniqueness: { message: 'must be unique & that name already exists' }, on: :create
  validates :description, presence: { message: "can't be blank, what is this supposed to do?" }, on: :create
  validates :authors, presence: { message: "can't be blank, put your username if nothing else" }, on: :create
  # validates :website, presence: { message: "can't be blank" }, on: :create
  validates :embed_url, presence: { message: "can't be blank" }, on: :create, if: :is_embeddable
  validate :reject_if_any_html

  scope :approved, -> { where(approved_at: ...Time.zone.now) }
  scope :pending, -> { where('approved_at IS NULL OR approved_at > ?', Time.zone.now) }

  after_create :create_notification

  has_attached_file :image,
                    default_style: :medium,
                    # default_url: "/images/defaults/app_:style.jpg",
                    default_url: '/images/defaults/app_:style.jpg',
                    url: '/system/:class/:attachment/:id/:basename_:style.:extension',
                    # path: ":rails_root/public/system/:class/:attachment/:id/:basename_:style.:extension",
                    styles: { large: '600x600>', medium: '300x300>', small: '100x100#', tiny: '32x32#' }
  # validates_attachment_presence :image
  # TODO: remove :if conditionals; only needed with new version of Paperclip + Rails 2.3 (???); Weird bug.
  validates_attachment_content_type :image, content_type: ['image/jpeg', 'image/pjpeg', 'image/jpg', 'image/gif', 'image/png', 'image/x-png'], message: 'Your thumbnail is not a valid image filetype (we accept JPG, PNG & GIF)', if: lambda { |e|
    e.image_file_name.present?
  }
  validates_attachment_size :image, less_than: 1.megabyte, message: 'Your thumbnail must be less than 1 megabyte (MB).', if: lambda { |e|
    e.image_file_name.present?
  }

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
      errors.add(key, 'is invalid') if value.present? && value.instance_of?(String) && value.match(/href=/)
    end
  end
end
