source 'https://rubygems.org'
ruby File.open(File.dirname(__FILE__)+'/.ruby-version', 'rb') { |f| f.read.chomp }

gem 'rails', '~> 8.0.2'
gem 'mysql2', '~> 0.5.7'
gem 'puma', groups: [:development, :production]

gem 'propshaft'
gem 'terser'
gem 'bootsnap', require: false
gem 'jquery-rails'
gem 'responders', '~> 3.0'
gem 'haml'
gem 'authlogic'
gem 'scrypt', '~> 3.0'
gem 'nokogiri', '~> 1.15'
gem 'kt-paperclip'
gem 'htmlentities'
gem 'will_paginate'
gem 'aws-sdk-s3', '~> 1.0'
gem 'rails_12factor'
gem 'dotenv-rails', groups: [:development, :test]
gem 'lograge'
gem 'invisible_captcha'
gem 'exception_notification'
gem 'bigdecimal', '~> 3.1'
gem 'rexml'
gem 'ostruct'

group :development, :test do
  gem 'rspec-rails', '~> 8.0'
  gem 'factory_bot'
  gem 'rails-controller-testing'
  gem 'rubocop', require: false
  gem 'rubocop-rails', require: false
  gem 'rubocop-rspec', require: false
end

group :development do
  gem 'ruby-lsp', require: false
end

group :development do
  # gem 'spring'
  # gem 'spring-commands-rspec'
  # gem 'disable_assets_logger'
end

