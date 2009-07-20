# == Schema Information
#
# Table name: tags
#
#  id            :integer(4)      not null, primary key
#  user_id       :integer(4)
#  title         :string(255)
#  slug          :string(255)
#  description   :text
#  comment_count :integer(4)
#  likes_count   :integer(4)
#  created_at    :datetime
#  updated_at    :datetime
#

require 'test_helper'

class TagTest < ActiveSupport::TestCase
  # Replace this with your real tests.
  test "the truth" do
    assert true
  end
end
