# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Favorite, type: :model do
  before do
    # FIXME: wish this could use :build; not saving associations
    @favorite = FactoryBot.create(:favorite)
  end

  it 'is valid' do
    expect(@favorite).to be_valid
  end

  it 'has a :user' do
    expect(@favorite.user).to be_valid
  end

  it 'has a polymorphic :object' do
    expect(@favorite.object).to be_valid
  end

  it 'makes a notification after create' do
    @user = FactoryBot.create(:user)
    @tag = FactoryBot.create(:tag)
    expect do
      described_class.create!(user: @user, object: @tag)
    end.to change(Notification, :count).by(1)
  end
end
