class User < ApplicationRecord
  # bcrypt, via password_digest. Validations are off because most rows predate
  # this column and would otherwise fail to save on any unrelated update.
  has_secure_password validations: false

  validates :password, confirmation: true, length: { minimum: 4 }, if: -> { password.present? }

  # Password reset links. Replaces Authlogic's perishable_token, which was a
  # column that never expired; this is signed and expires on its own.
  generates_token_for :password_reset, expires_in: 1.day do
    # Changing the password invalidates any outstanding reset link.
    (password_digest.presence || legacy_crypted_password).to_s.last(10)
  end

  # Returns the user when the password is right, otherwise nil.
  #
  # Accounts created before the move off Authlogic have only an scrypt hash in
  # crypted_password. scrypt cannot be converted to bcrypt, so those are checked
  # against the old scheme and quietly rehashed here, one login at a time.
  def self.authenticate_by_credentials(login_or_email, password)
    user = find_by_login_or_email(login_or_email.to_s.strip)
    return nil if user.nil? || password.blank?

    if user.password_digest.present?
      user.authenticate(password) || nil
    elsif user.authenticate_legacy_scrypt(password)
      user.migrate_password_to_bcrypt!(password)
      user
    end
  end

  # Verify against the scrypt hash Authlogic wrote.
  #
  # The hashed string is the password with the salt appended, in that order.
  # Authlogic's encrypt_arguments returns [raw_password, salt] and its SCrypt
  # provider joins them, so reversing these silently fails every legacy login.
  # spec/models/user_spec.rb pins the order against a real Authlogic hash.
  def authenticate_legacy_scrypt(password)
    return false if legacy_crypted_password.blank?

    ::SCrypt::Password.new(legacy_crypted_password) == "#{password}#{legacy_password_salt}"
  rescue ::SCrypt::Errors::InvalidHash
    false
  end

  # has_secure_password defines its own password_salt, derived from the bcrypt
  # digest, which shadows the legacy column of the same name and returns nil
  # while password_digest is empty. Read the columns directly so the two
  # schemes stop colliding.
  def legacy_crypted_password = self[:crypted_password]
  def legacy_password_salt    = self[:password_salt]

  def migrate_password_to_bcrypt!(password)
    update_column(:password_digest, ::BCrypt::Password.create(password))
  end

  # FIXME: manually reimplmenting this for now...
  # should we just use friendly_id?
  # has_slug :login

  has_many :favorites
  has_many :tags
  has_many :visualizations
  has_many :notifications

  validates :login, presence: { message: "can't be blank" },
                    uniqueness: { message: "is already taken by another user; try a different one." }, on: :create
  validates :email, presence: { message: "can't be blank" },
                    uniqueness: { message: "already exists in our system; an email address can only be used once." }, on: :create
  validates :iphone_uniquekey, uniqueness: { message: "has already been claimed by another user! If you believe this is an error email the admins => info@000000book.com" }, on: :save, unless: lambda {
    iphone_uniquekey.blank?
  }
  # TODO: email regex validation

  has_one_attached :photo do |attachable|
    attachable.variant :medium, resize_to_limit: [300, 300]
    attachable.variant :small,  resize_to_fill:  [100, 100]
    attachable.variant :tiny,   resize_to_fill:  [32, 32]
  end

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
    UserMailer.password_reset_instructions(self).deliver_now
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
