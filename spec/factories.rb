require 'rubygems'
require 'factory_girl'


Factory.define :user do |t|
  # TODO
end

# - UserSession?
# - PasswordReset?

Factory.define :tag do |t|
  # TODO
end

Factory.define :visualization do |t|
  # TODO
end

Factory.define :favorite do |t|
  # t.user { |a| a.association(:user) }
  # t.object_type 'Tag'
  # t.object_id 1
end

Factory.define :comment do |t|
  # TODO
end

Factory.define :gml_object do |t|
  t.tag_id 1
  t.data "<gml><client><name>GML</name></client><drawing><stroke><pt>x</pt><pt>y</pt></stroke></drawing></gml>"
end

