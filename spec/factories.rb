require 'factory_bot'

# FIXME should not be a constant
DEFAULT_GML = "<gml><tag><header><environment><name>rspec</name></client></environment><drawing><stroke><pt><x>0</x><y>0</y><time>0</time></pt></stroke></drawing></tag></gml>"

include FactoryBot::Syntax::Methods

FactoryBot.define do
  sequence :login do |i|
    "user#{i}_#{rand(100000)}"
  end

  sequence :email do |i|
    "user#{i}_#{rand(100000)}@000book.com"
  end

  sequence :device_id do |i|
    Digest::SHA1.hexdigest(i.to_s)
  end

  factory :user do
    login { FactoryBot.generate(:login) }
    name { 'Test User' }
    email  { FactoryBot.generate(:email) }
    password { 'topsecret123' }
    website { 'http://fffff.at' }
    tagline { 'I did it for the famo' }
    about { 'Blah blah blah, http://jamiedubs.com, even some <b>BOLD TEXT</b> or <a href="http://fffff.at">custom link</a>' }
    iphone_uniquekey  { FactoryBot.generate(:device_id) }
  end

  factory :admin, parent: :user do
    login { 'admin' }
    name { 'Admin User' }
    admin { true }
  end

  # A minimum GML tag
  factory :tag do
    association :user
    application { 'TestApp' }
    gml_application { 'testing_app_maybe' }
    author { 'JDUBS' }
    # gml_object { association(:gml_object) }
    data { DEFAULT_GML }
  end

  # A tag sent via the API is slightly different than through the site
  # No thumbnail required & application *is* required
  factory :tag_from_api, parent: :tag do
    remote_image { 'http://fffff.at/fuckflickr/...' }
    remote_secret { '' }
  end

  # Stores the actual GML
  factory :gml_object do
    tag_id { 1 }
    data { DEFAULT_GML }
  end

  # A GML application
  factory :visualization do
    association :user
    name { "TestTagger_#{rand(100000)}" }
    description { "A really cool app with which you can draw tags"}
    website { "http://jamiedubs.com/testtagger" }
    authors { "jamiedubs" }
    kind { "javascript" }
  end

  factory :favorite do
    association :user
    association :object, factory: :tag
  end

end
