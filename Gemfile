source 'https://rubygems.org'
ruby File.open('.ruby-version', 'rb') { |f| f.read.chomp }

gem 'rails', '4.2.10'
gem 'pg', '~> 0.15'
gem 'puma', groups: [:development, :production]

gem 'uglifier'
gem 'jquery-rails'
gem 'responders', '~> 2.0'
gem 'haml'
gem 'authlogic'
gem 'nokogiri', '~> 1.8.2'
gem 'paperclip'
gem 'htmlentities'
gem 'will_paginate'
gem 'protected_attributes'
# FIXME gem 'has_slug' for slugs
gem 'aws-sdk', '~> 2'
gem 'ipfs', require: 'ipfs/client'
gem 'rails_12factor'

group :development, :test do
  gem 'byebug'
  gem 'rspec-rails', '~> 3.0'
  gem 'factory_bot'
end

group :development do
  gem 'spring'
  gem 'spring-commands-rspec'
  # gem 'disable_assets_logger'
end

