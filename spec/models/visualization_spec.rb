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

  # TODO: some other required fields -- description, authors, embed_url (if embeddable)

  it "fails if you put HTML links in fields" do
    expect(FactoryBot.build(:visualization, authors: '<a href="me.com">it me</a>')).to be_invalid
    expect(FactoryBot.build(:visualization, description: 'more stuff <a href="me.com">it me</a> ok spam')).to be_invalid
  end

  describe "API output" do
    # /apps/:id.json and .xml exist by accident, via the responders gem falling
    # back to api_behavior. This makes sure they only ever serve chosen fields.
    it "classifies every column as either public or private" do
      classified = described_class::PUBLIC_ATTRIBUTES + described_class::PRIVATE_ATTRIBUTES
      unclassified = described_class.column_names - classified

      expect(unclassified).to be_empty,
                              "not in PUBLIC_ATTRIBUTES or PRIVATE_ATTRIBUTES: #{unclassified.join(', ')}"
      expect(classified - described_class.column_names).to be_empty
      expect(described_class::PUBLIC_ATTRIBUTES & described_class::PRIVATE_ATTRIBUTES).to be_empty
    end

    it "does not publish internal owner ids" do
      viz = FactoryBot.create(:visualization, approved_by: 99)

      %i[to_json to_xml].each do |format|
        expect(viz.public_send(format)).not_to include('user_id', 'approved_by')
      end
    end
  end
end
