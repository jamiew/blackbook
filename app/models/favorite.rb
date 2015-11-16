class Favorite < ActiveRecord::Base

  belongs_to :object, :polymorphic => true
  belongs_to :user

  validates_presence_of :object_id, :on => :create, :message => "can't be blank"
  validates_presence_of :object_type, :on => :create, :message => "can't be blank"
  validates_associated :object, :on => :create

  validates_presence_of :user_id, :on => :create, :message => "can't be blank"
  validates_uniqueness_of :user_id, :scope => [:object_id, :object_type], :on => :create, :message => "must be unique"
  validates_associated :user, :on => :create

  after_create :create_notification

  scope :tags, -> { where('object_type = "Tag"') }

protected

  def create_notification
    Notification.create(:subject => self, :verb => 'created', :user => self.user)
  end

end
