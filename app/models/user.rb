# == Schema Information
#
# Table name: users
#
#  id                :integer(4)      not null, primary key
#  created_at        :datetime
#  updated_at        :datetime
#  login             :string(255)     not null
#  email             :string(255)     default(""), not null
#  crypted_password  :string(255)     not null
#  password_salt     :string(255)     not null
#  persistence_token :string(255)     not null
#  perishable_token  :string(255)     default(""), not null
#  login_count       :integer(4)      default(0), not null
#  last_request_at   :datetime
#  last_login_at     :datetime
#  current_login_at  :datetime
#  last_login_ip     :string(255)
#  current_login_ip  :string(255)
#  admin             :boolean(1)
#
# Indexes
#
#  index_users_on_login              (login)
#  index_users_on_persistence_token  (persistence_token)
#  index_users_on_last_request_at    (last_request_at)
#  index_users_on_perishable_token   (perishable_token)
#  index_users_on_email              (email)
#

class User < ActiveRecord::Base
  acts_as_authentic
  acts_as_commentable # user wall
  
  # TODO: validations? any from aa_authentic...?
  

  has_attached_file :photo, :styles => { :medium => "300x300>", :thumb => "100x100>" }


  def deliver_password_reset_instructions!
    reset_perishable_token!
    Notifier.deliver_password_reset_instructions(self)
  end

  class << self
    def find_by_login_or_email(val)
      find_by_login(val) || find_by_email(val)
    end
  end # class << self
end
