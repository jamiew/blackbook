# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Comment, type: :model do
  it 'factory should be valid' do
    # invalid if we just use :build; doesn't save associations
    comment = FactoryBot.create(:comment)
    expect { comment.save! }.not_to raise_error
  end

  it 'fails without a commentable object' do
    expect(FactoryBot.build(:comment, commentable: nil)).not_to be_valid
  end

  it 'is invalid with blank text' do
    expect(FactoryBot.build(:comment, text: '')).not_to be_valid
  end
end
