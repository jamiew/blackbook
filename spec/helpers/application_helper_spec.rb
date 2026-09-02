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

  describe '#website_link' do
    it 'is nil for a blank website' do
      expect(helper.website_link(nil)).to be_nil
      expect(helper.website_link('')).to be_nil
    end

    it 'adds a scheme when none was typed and strips it from the label' do
      html = helper.website_link('example.com/')
      expect(html).to include('href="http://example.com/"')
      expect(html).to include('>example.com<')
    end

    it 'keeps https' do
      expect(helper.website_link('https://example.org')).to include('href="https://example.org"')
    end
  end
end
