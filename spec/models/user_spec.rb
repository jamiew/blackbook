
# == Schema Information
#
# Table name: users
#
#  id                 :integer(4)      not null, primary key
#  created_at         :datetime
#  updated_at         :datetime
#  login              :string(255)     not null
#  email              :string(255)     default(""), not null
#  crypted_password   :string(255)     not null
#  password_salt      :string(255)     not null
#  persistence_token  :string(255)     not null
#  perishable_token   :string(255)     default(""), not null
#  login_count        :integer(4)      default(0), not null
#  last_request_at    :datetime
#  last_login_at      :datetime
#  current_login_at   :datetime
#  last_login_ip      :string(255)
#  current_login_ip   :string(255)
#  admin              :boolean(1)
#  photo_file_name    :string(255)
#  photo_content_type :string(255)
#  photo_file_size    :integer(4)
#  photo_updated_at   :datetime
#  website            :string(255)
#  tagline            :string(255)
#  about              :text
#  location           :string(255)
#  slug               :string(255)
#  name               :string(255)
#
# Indexes
#
#  index_users_on_login              (login)
#  index_users_on_persistence_token  (persistence_token)
#  index_users_on_last_request_at    (last_request_at)
#  index_users_on_perishable_token   (perishable_token)
#  index_users_on_email              (email)
#

