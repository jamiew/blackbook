require 'rubygems'
require 'factory_girl'

DEFAULT_GML = "<gml><tag><header><environment><name>rspec</name></client></environment><drawing><stroke><pt><x>0</x><y>0</y><time>0</time></pt></stroke></drawing></tag></gml>"

Factory.sequence :login do |i|
  "user#{i}"
end

Factory.sequence :email do |i|
  "user#{i}@000book.com"
end

Factory.sequence :device_id do |i|
  Digest::SHA1.hexdigest(i.to_s)
end

Factory.define :user do |t|
  t.login { Factory.next(:login) }
  t.name 'Test User'
  t.email  { Factory.next(:email) }
  t.password 'topsecret123'
  t.password_confirmation 'topsecret123'
  t.website 'http://fffff.at'
  t.tagline 'I did it for the famo'
  t.about 'Blah blah blah, http://jamiedubs.com, even some <b>BOLD TEXT</b> or <a href="http://fffff.at">custom link</a>'
  t.iphone_uniquekey  { Factory.next(:device_id) }
end

Factory.define :admin, :parent => :user do |t|
  t.login 'adminner'
  t.name 'Admin Yep'
  t.admin true
end

# A minimum GML tag
Factory.define :tag do |t|
  t.user {|a| a.association(:user) }
  t.application 'TestApp'
  t.author 'JDUBS'
  # t.gml_object {|a| a.association(:gml_object) }
  t.gml DEFAULT_GML
end

# A tag sent via the API is slightly different than through the site
# No thumbnail required & application *is* required
Factory.define :tag_from_api, :parent => :tag do |t|
  t.remote_image 'http://fffff.at/fuckflickr/...'
  t.remote_secret ''
  # t.gml_object {|a| a.association(:gml_object) }
  t.gml DEFAULT_GML
end

# A sample tag from Tempt1's EyeWriter.
# He can't upgrade or diagnose issues, so we *must* maintain backwards-compat
Factory.define :tag_from_tempt1, :parent => :tag do |t|
  t.remote_secret '123456789' # FIXME use tempt's real key
  t.gml "<gml>yo i am some sample tempt graffiti... should use a fixture to store this</gml>"
end

# Stores the actual GML
Factory.define :gml_object, :class => GMLObject do |t|
  t.tag_id 1
  t.data "<gml><tag><header><environment><name>rspec</name></client></environment><drawing><stroke><pt><x>0</x><y>0</y><time>0</time></pt></stroke></drawing></tag></gml>"
end

# A GML application
Factory.define :visualization do |t|
  t.name "Jdubs TestTag"
  t.website "http://jamiedubs.com/yep"
  t.kind 'javascript'
end

Factory.define :favorite do |t|
  t.user {|a| a.association(:user) }
  t.object {|a| a.association(:tag) }
end

Factory.define :comment do |t|
  t.user {|a| a.association(:user) }
  t.commentable {|a| a.association(:tag) }
end


