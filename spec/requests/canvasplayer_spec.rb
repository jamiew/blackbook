require 'rails_helper'

# The player is vendored under public/ rather than the asset pipeline, because
# Propshaft fingerprints filenames and that breaks the modules' relative
# imports. This pins the path the layout advertises to files that exist.
RSpec.describe 'vendored canvasplayer' do
  let(:base) { ApplicationController.helpers.canvasplayer_path }

  it 'serves every module at the path the layout points to' do
    %w[gml.js gml-player.js gml-ui.js gml-ui.css].each do |file|
      get "#{base}/#{file}"
      expect(response).to have_http_status(:ok), file
    end
  end

  it 'records the commit it came from' do
    expect(Rails.root.join("public#{base}/SOURCE").read).to match(/Commit:\s+[0-9a-f]{40}/)
  end

  it 'tells the page where it is' do
    get '/'
    expect(response.body).to match(/<meta[^>]*name="canvasplayer"[^>]*>/)
    expect(response.body).to match(/<meta[^>]*content="#{Regexp.escape(base)}"[^>]*>/)
  end
end
