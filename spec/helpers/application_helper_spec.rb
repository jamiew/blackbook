require 'rails_helper'

describe ApplicationHelper do
  describe '#attachment_url' do
    let(:user) { FactoryBot.create(:user) }

    it 'falls back to the default when nothing is attached' do
      expect(helper.attachment_url(user, :photo, :tiny)).to eq('/images/defaults/photo_tiny.jpg')
    end

    # The corpus holds zero-byte and truncated images. Active Storage refuses to
    # build a variant from those, and one bad row used to 500 a whole index.
    it 'falls back to the default rather than raising on an unvariable file' do
      user.photo.attach(io: StringIO.new('not an image'), filename: 'junk.bin',
                        content_type: 'application/octet-stream')

      expect(helper.attachment_url(user, :photo, :tiny)).to eq('/images/defaults/photo_tiny.jpg')
    end
  end
end
