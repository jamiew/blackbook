require 'rubygems'
require 'factory_girl'


Factory.define :user do |t|
  t.login 'test1'
  t.name 'Test User'
  t.email 'test@000000book.com'
  t.website 'http://fffff.at'
  t.tagline 'I did it for the famo'
  t.about 'Blah blah blah, http://jamiedubs.com, even a <b>BOLD TEXT</b> or <h1>HEADER</h1>'
  t.iphone_uniquekey 'ff00ff' #bunk (for now)
end

# - UserSession?
# - PasswordReset?

Factory.define :tag do |t|
  t.user { |a| a.association(:user) }
  t.application 'DemoTag' #ghetto
  t.author 'JDUBS'
  #TODO: should read GML header somehow...?
  #TODO: how to store/cache the GML? HRMZ.
end

Factory.define :api_tag, :parent => :tag do |t|
  # anonymous and with some bunk fields, including client or secret maybe
  t.remote_image 'http://fffff.at/fuckflickr/...'
  t.remote_secret 'tempt1' #TODO: use tempt's secret code here?
end

Factory.define :tempt_api_tag, :parent => :tag do |t|
  
end

Factory.define :gml_object do |t|
  t.tag_id 1
  t.data "<gml><client><name>GML</name></client><drawing><stroke><pt>x</pt><pt>y</pt></stroke></drawing></gml>"
end

Factory.define :visualization do |t|
  t.name "Jdubs testtag"
  t.website "http://jamiedubs.com/yep"
  t.kind 'javascript'
  #...  
end

Factory.define :favorite do |t|
  t.user { |a| a.association(:user) }
  t.object_type 'Tag'
  t.object_id 1
end

Factory.define :comment do |t|
  t.user { |a| a.association(:user) }
  t.object_type 'Tag'
  t.object_id 1
  # TODO
end


