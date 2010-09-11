require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Notification do
  before(:each) do
    @valid_attributes = {
      :subject_id => 1,
      :subject_type => "Comment",
      :verb => "created",
      :user_id => 1,
      :supplement_id => 1,
      :supplement_type => "Video"
    }
  end

  it "should create a new instance given valid attributes" do
    Notification.create!(@valid_attributes)
  end
end
