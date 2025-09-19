# frozen_string_literal: true

class User < ApplicationRecord
  acts_as_authentic do |c|
    c.crypto_provider = ::Authlogic::CryptoProviders::SCrypt
  end

  # Add password confirmation support for forms
  attr_accessor :password_confirmation

  validates :password, confirmation: { if: :password_changed? }

  # FIXME: manually reimplmenting this for now...
  # should we just use friendly_id?
  # has_slug :login

  has_many :comments # Owns/has made
  has_many :wall_posts, class_name: 'Comment', as: :commentable # Comments *on* this user
  has_many :favorites
  has_many :tags
  has_many :visualizations
  has_many :notifications

  validates :login, presence: { message: "can't be blank" },
                    uniqueness: { message: 'is already taken by another user; try a different one.' }, on: :create
  validates :email, presence: { message: "can't be blank" },
                    uniqueness: { message: 'already exists in our system; an email address can only be used once.' }, on: :create
  validates :iphone_uniquekey, uniqueness: { message: 'has already been claimed by another user! If you believe this is an error email the admins => info@000000book.com' }, on: :save, unless: lambda {
    iphone_uniquekey.blank?
  }
  # TODO: email regex validation

  has_attached_file :photo,
                    styles: { medium: '300x300>', small: '100x100#', tiny: '32x32#' },
                    path: ':rails_root/public/system/photos/:id/:style/:filename',
                    url: '/system/photos/:id/:style/:filename'

  after_create  :create_notification
  after_save    :activate_device_pairing

  def to_param
    login || id
  end

  def self.find_by_param(param)
    find_by(login: param) || find_by(id: param)
  end

  def self.find_by_login_or_email(val)
    find_by(login: val) || find_by(email: val)
  end

  def deliver_password_reset_instructions!
    reset_perishable_token!
    Mailer.password_reset_instructions(self).deliver_now
  end

  # Unclaimed tags matching this user's uniqueKey
  def matching_device_tags
    @matching_device_tags ||= Tag.unclaimed.where(gml_uniquekey: iphone_uniquekey)
  end

  protected

  def create_notification
    Notification.create(subject: self, verb: 'created', user: self)
  end

  # Claim some tags if our user iphone_uniquekey changed
  def activate_device_pairing
    return unless iphone_uniquekey_changed? && iphone_uniquekey.present?

    # Associate new tags
    new_tags = matching_device_tags
    new_tags.update_all(user_id: id)

    # Disassociate old tags (only 1 at a time!)
    old_tags = Tag.claimed.where(gml_uniquekey: iphone_uniquekey_was)
    old_tags.update_all(user_id: nil)

    logger.debug "User#activate_device_pairing: associated #{new_tags.length} new tags from #{iphone_uniquekey.inspect}; disassociated #{old_tags.length} old tags from previous key #{iphone_uniquekey_was.inspect}"
    true # ??
  end
end
