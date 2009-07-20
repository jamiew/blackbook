# == Schema Information
#
# Table name: notifications
#
#  id              :integer(4)      not null, primary key
#  subject_id      :string(255)
#  subject_type    :string(255)
#  verb            :string(255)
#  user_id         :integer(4)
#  supplement_id   :integer(4)
#  supplement_type :string(255)
#  created_at      :datetime
#  updated_at      :datetime
#

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Notification do
  before(:each) do
    @valid_attributes = {
      :subject_id => "value for subject_id",
      :subject_type => "value for subject_type",
      :verb => "value for verb",
      :user_id => 1,
      :supplement_id => 1,
      :supplement_type => "value for supplement_type"
    }
  end

  it "should create a new instance given valid attributes" do
    Notification.create!(@valid_attributes)
  end
end
