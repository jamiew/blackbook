require 'rails_helper'

RSpec.describe Visualization, type: :model do

  it "factory is valid" do
    # doing a .build doesn't save the user association, so let's build that on our own
    user = FactoryBot.create(:user)
    expect(FactoryBot.build(:visualization, user: user)).to be_valid
  end

  it "is invalid without a user" do
    expect { FactoryBot.create(:visualization, user: nil) }.to raise_error
  end

  it "is invalid without a name" do
    expect { FactoryBot.create(:visualization, name: '') }.to raise_error
  end

  # TODO some other required fields -- description, authors, embed_url (if embeddable)

  it "fails if you put HTML links in fields" do
    expect(FactoryBot.build(:visualization, authors: '<a href="me.com">it me</a>')).to be_invalid
    expect(FactoryBot.build(:visualization, description: 'more stuff <a href="me.com">it me</a> ok spam')).to be_invalid
  end


end
