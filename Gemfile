source 'https://rubygems.org'
ruby File.open('.ruby-version', 'rb') { |f| f.read.chomp }

gem 'rails', '4.2.10'
gem 'mysql2', '>= 0.3.13', '< 0.5', groups: [:development, :production]
gem 'puma', groups: [:development, :production]

gem 'sass-rails', '~> 5.0'
gem 'uglifier', '>= 1.3.0'
gem 'coffee-rails', '~> 4.1.0'
gem 'jquery-rails'
# gem 'turbolinks'
# gem 'jbuilder', '~> 2.0'
# gem 'sdoc', '~> 0.4.0', group: :doc
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
# gem 'exception_notification'
gem "exception_notification", github: "smartinez87/exception_notification", branch: "master"

group :development, :test do
  gem 'byebug'
  gem 'rspec-rails', '~> 3.0'
  gem 'factory_girl'
  gem 'sqlite3'
end

group :development do
  gem 'web-console', '~> 2.0'
  gem 'spring'
  gem 'spring-commands-rspec'
  # gem 'disable_assets_logger'
end

