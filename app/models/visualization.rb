class Visualization < ActiveRecord::Base

  # supported application types; stored as an Array to maintain order pre-ruby 1.9
  # possibly rename to 'language'? Not sure. Little distinction atm
  KINDS = [
      ['',''], #Other/misc
      ['Flash','flash'],
      ['Javascript','javascript'],
      ['C++','cpp'],
      ['openFrameworks (C++)','openframeworks'],
      ['Processing','processing'],
      ['Ruby','ruby'],
      ['Python','python'],
      ['Java','java'],
      ['Other','other'],
    ]

  belongs_to :user
  has_many :comments, :as => :commentable

  validates_presence_of :user_id, :on => :create, :message => "can't be blank"
  validates_associated :user, :on => :create
  validates_presence_of :name, :on => :create, :message => "can't be blank (and should be cool)"
  validates_uniqueness_of :name, :on => :create, :message => "must be unique & that name already exists"
  validates_presence_of :description, :on => :create, :message => "can't be blank, what is this supposed to do?"
  validates_presence_of :authors, :on => :create, :message => "can't be blank, put your username if nothing else"
  # validates_presence_of :website, :on => :create, :message => "can't be blank"
  validates_presence_of :embed_url, :on => :create, :message => "can't be blank", :if => :is_embeddable

  attr_protected :user_id, :slug

  scope :approved, -> { where('approved_at < ?', Time.now) }
  scope :pending, -> { where('approved_at IS NULL OR approved_at > ?', Time.now) }

  after_create :create_notification

  has_attached_file :image,
    :default_style => :medium,
    # :default_url => "/images/defaults/app_:style.jpg",
    :default_url => "/images/defaults/app_:style.jpg",
    :url => "/system/:class/:attachment/:id/:basename_:style.:extension",
    # :path => ":rails_root/public/system/:class/:attachment/:id/:basename_:style.:extension",
    :styles => { :large => '600x600>', :medium => "300x300>", :small => '100x100#', :tiny => "32x32#" }
  # validates_attachment_presence :image
  #TODO: remove :if conditionals; only needed with new version of Paperclip + Rails 2.3 (???); Weird bug.
	validates_attachment_content_type :image, :content_type => ['image/jpeg', 'image/pjpeg', 'image/jpg', 'image/gif', 'image/png', 'image/x-png'], :message => "Your thumbnail is not a valid image filetype (we accept JPG, PNG & GIF)", :if => lambda { |e| !e.image_file_name.blank? }
  validates_attachment_size :image, :less_than => 1.megabyte, :message => 'Your thumbnail must be less than 1 megabyte (MB).', :if => lambda { |e| !e.image_file_name.blank? }


  def approved?
    self.approved_at && self.approved_at < Time.now
  end

protected
  def create_notification
    Notification.create(:subject => self, :verb => 'created', :user => self.user)
  end

end
