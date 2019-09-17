require 'rails_helper'

RSpec.describe Comment, type: :model do

  it "factory should be valid" do
    # invalid if we just use :build; doesn't save associations
    comment = FactoryBot.create(:comment)
    lambda { comment.save! }.should_not raise_error
  end

  it "should fail without a commentable object" do
    FactoryBot.build(:comment, commentable: nil).should_not be_valid
  end

  it "should be invalid with blank text" do
    FactoryBot.build(:comment, text: '').should_not be_valid
  end
end
