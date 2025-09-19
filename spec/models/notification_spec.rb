# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Notification, type: :model do
  before do
    @valid_attributes = {
      subject_id: 1,
      subject_type: 'Comment',
      verb: 'created',
      user_id: 1,
      supplement_id: 1,
      supplement_type: 'Video'
    }
  end

  it 'creates a new instance given valid attributes' do
    described_class.create!(@valid_attributes)
  end
end
