require 'rubygems'
require 'factory_girl'

Factory.define :user do |t|
end

Factory.define :tag do |t|
end

Factory.define :visualization do |t|
end

Factory.define :favorite do |t|
  # t.user { |a| a.association(:user) }
  # t.object_type 'Tag'
  # t.object_id 1
end