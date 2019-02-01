require 'rails_helper'

RSpec.describe Comment, type: :model do

  before do
    @comment = FactoryBot.build(:comment)
  end

  it "factory should be valid" do
    @comment.should be_valid
    lambda { @comment.save! }.should_not raise_error
  end

  it "should fail without a commentable object" do
    FactoryBot.build(:comment, commentable: nil).should_not be_valid
  end

  it "should be invalid with blank text" do
    FactoryBot.build(:comment, text: '').should_not be_valid
  end
end
