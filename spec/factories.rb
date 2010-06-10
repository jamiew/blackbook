require 'rubygems'
require 'factory_girl'

Factory.define :user do |t|
  t.login 'jamiew'
  t.name 'Test User'
  t.email 'test@000000book.com'
  t.password 'topsecret123'
  t.password_confirmation 'topsecret123'
  t.website 'http://fffff.at'
  t.tagline 'I did it for the famo'
  t.about 'Blah blah blah, http://jamiedubs.com, even a <b>BOLD TEXT</b> or <h1>HEADER</h1>'
  # t.iphone_uniquekey 'ff00ff' # FIXME
end

Factory.define :admin, :parent => :user do |t|
  t.login 'adminner'
  t.name 'Admin Yep'
  t.admin true
end

# A typical tag
Factory.define :tag do |t|
  t.user { |a| a.association(:user) }
  t.application 'TestApp'
  t.author 'JDUBS'
  t.keywords 'testapp,police,car'
  #TODO: should read GML header somehow...?
  #TODO: how to store/cache the GML? HRMZ.
end

# A tag sent via the API is different than through the site
# e.g. no thumbnail required, application *is* required, etc
Factory.define :api_tag, :parent => :tag do |t|
  t.remote_image 'http://fffff.at/fuckflickr/...'
  t.remote_secret '' # none at all
end

# A sample tag from Tempt1's EyeWriter.
# He can't upgrade, we must maintain backwards-compat
Factory.define :tempt_api_tag, :parent => :tag do |t|
  t.remote_secret '123456789' # FIXME use his real key
  t.gml "<gml>yo i am some sample tempt graffiti... TODO could use a fixture to store this</gml>"
end

# Datastore... todo will make binary/gzipped as needed, or just store as JSON
Factory.define :gml_object, :class => GMLObject do |t|
  t.tag_id 1
  t.data "<gml><header><client><name>rspec</name></client></header><drawing><stroke><pt><x>0</x><y>0</y><time>0</time></pt></stroke></drawing></gml>"
end

# An application -- not using that name since its application_controller...
Factory.define :visualization do |t|
  t.name "Jdubs testtag"
  t.website "http://jamiedubs.com/yep"
  t.kind 'javascript'
  #...
end

Factory.define :favorite do |t|
  t.user { |a| a.association(:user) }
  # t.object_type 'Tag'
  # t.object_id 1
  # ^^ FIXME terrible naming scheme, sorry dewds
end

Factory.define :comment do |t|
  t.user { |a| a.association(:user) }
  t.commentable_type 'Tag'
  t.commentable_id 1
  # TODO
end


