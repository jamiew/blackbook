# == Schema Information
#
# Table name: visualizations
#
#  id          :integer(4)      not null, primary key
#  user_id     :integer(4)
#  name        :string(255)
#  slug        :string(255)
#  description :text
#  created_at  :datetime
#  updated_at  :datetime
#

class Visualization < ActiveRecord::Base
  acts_as_commentable
end
