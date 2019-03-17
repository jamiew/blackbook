require 'factory_bot'

# FIXME should not be a constant
DEFAULT_GML = "<gml><tag><header><environment><name>rspec</name></client></environment><drawing><stroke><pt><x>0</x><y>0</y><time>0</time></pt></stroke></drawing></tag></gml>"

include FactoryBot::Syntax::Methods

FactoryBot.define do
  sequence :login do |i|
    "user#{i}"
  end

  sequence :email do |i|
    "user#{i}@000book.com"
  end

  sequence :device_id do |i|
    Digest::SHA1.hexdigest(i.to_s)
  end

  factory :user do |t|
    t.login { FactoryBot.generate(:login) }
    t.name { 'Test User' }
    t.email  { FactoryBot.generate(:email) }
    t.password { 'topsecret123' }
    t.password_confirmation { 'topsecret123' }
    t.website { 'http://fffff.at' }
    t.tagline { 'I did it for the famo' }
    t.about { 'Blah blah blah, http://jamiedubs.com, even some <b>BOLD TEXT</b> or <a href="http://fffff.at">custom link</a>' }
    t.iphone_uniquekey  { FactoryBot.generate(:device_id) }
  end

  factory :admin, parent: :user do |t|
    t.login { 'admin' }
    t.name { 'Admin User' }
    t.admin { true }
  end

  # A minimum GML tag
  factory :tag do |t|
    t.user {|a| a.association(:user) }
    t.application { 'TestApp' }
    t.gml_application { 'testing_app_maybe' }
    t.author { 'JDUBS' }
    # t.gml_object {|a| a.association(:gml_object) }
    t.data { DEFAULT_GML }
    t.size { 12345 }
    t.ipfs_hash { "Qmd3ADB33FBeeFbEeFlol" }

  end

  # A tag sent via the API is slightly different than through the site
  # No thumbnail required & application *is* required
  factory :tag_from_api, parent: :tag do |t|
    t.remote_image { 'http://fffff.at/fuckflickr/...' }
    t.remote_secret { '' }
  end

  # A sample tag from Tempt1's EyeWriter.
  # He can't upgrade or diagnose issues, so we *must* maintain backwards compatibility
  factory :tag_from_tempt1, parent: :tag do |t|
    t.remote_secret { '123456789' }
    t.gml { "<gml>yo i am some sample tempt graffiti... should use a fixture to store this</gml>" }
  end

  # Stores the actual GML
  factory :gml_object do |t|
    t.tag_id { 1 }
    t.data { DEFAULT_GML }
  end

  # A GML application
  factory :visualization do |t|
    t.name { 'Jdubs TestTag' }
    t.website { "http://jamiedubs.com/yep" }
    t.kind { 'javascript' }
  end

  factory :favorite do |t|
    t.user {|a| a.association(:user) }
    t.object {|a| a.association(:tag) }
  end

  factory :comment do |t|
    t.user {|a| a.association(:user) }
    t.commentable {|a| a.association(:tag) }
    t.text { 'Default comment yo' }
  end

end
