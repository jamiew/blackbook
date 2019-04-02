source 'https://rubygems.org'
ruby File.open(File.dirname(__FILE__)+'/.ruby-version', 'rb') { |f| f.read.chomp }

gem 'rails', '4.2.11'
gem 'pg', '~> 0.15'
gem 'mysql2', '~> 0.4.10'
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
gem 'aws-sdk', '~> 2'
gem 'ipfs', require: 'ipfs/client'
gem 'rails_12factor'
gem 'dotenv-rails', groups: [:development, :test]
gem 'lograge'
gem 'invisible_captcha'
gem 'exception_notification'

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

