class User < ActiveRecord::Base

  acts_as_authentic

  # has_slug :login

  has_many :comments # Owns/has made
  has_many :wall_posts, :class_name => 'Comment', :as => :commentable # Comments *on* this user
  has_many :favorites
  has_many :tags
  has_many :visualizations
  has_many :notifications

  # attr_protected :admin

  validates_presence_of :login, :on => :create, :message => "can't be blank"
  validates_uniqueness_of :login, :on => :create, :message => "is already taken by another user; try a different one."
  validates_presence_of :email, :on => :create, :message => "can't be blank"
  validates_uniqueness_of :email, :on => :create, :message => "already exists in our system; an email address can only be used once."
  validates_uniqueness_of :iphone_uniquekey, :on => :save, :message => "has already been claimed by another user! If you believe this is an error email the admins => info@000000book.com", :unless => lambda { |u| u.iphone_uniquekey.blank? }
  #TODO email regex validation

  has_attached_file :photo,
    :styles => { :medium => "300x300>", :small => "100x100#", :tiny => '32x32#' }

  after_create  :create_notification
  after_save    :activate_device_pairing

  def deliver_password_reset_instructions!
    reset_perishable_token!
    Mailer.deliver_password_reset_instructions(self)
  end

  #FIXME: move to lib or elsewhere
  class << self
    def find_by_login_or_email(val)
      find_by_login(val) || find_by_email(val)
    end
  end # class << self

  # Tags matching our uniqueKey (not necessarily owned by us?)
  def matching_device_tags
    @matching_device_tags ||= Tag.unclaimed.by_uniquekey(self.iphone_uniquekey)
  end

protected

  def create_notification
    Notification.create(:subject => self, :verb => 'created', :user => self)
  end

  # Claim some tags if our user iphone_uniquekey changed
  def activate_device_pairing
    return unless self.iphone_uniquekey_changed? && !self.iphone_uniquekey.blank?

    # Associate new tags
    new_tags = matching_device_tags
    new_tags.update_all(:user_id => self.id)

    # Disassociate old tags (only 1 at a time!)
    old_tags = Tag.claimed.by_uniquekey(self.iphone_uniquekey_was) #manual; TODO methodize
    old_tags.update_all(:user_id => nil)

    logger.info "Associated #{new_tags.length} new tags from #{self.iphone_uniquekey.inspect}; disassociated #{old_tags.length} old tags from previous key #{self.iphone_uniquekey_was.inspect}"
    return true #??
  end
end

