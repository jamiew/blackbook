source 'https://rubygems.org'
ruby File.open(File.dirname(__FILE__)+'/.ruby-version', 'rb') { |f| f.read.chomp }

gem 'rails', '~> 8.1.0'
gem 'mysql2'
gem 'puma'

# Assets
gem 'propshaft'
gem 'terser'

# Performance
gem 'bootsnap', require: false

# Frontend
gem 'jquery-rails'
gem 'haml'

# Auth
gem 'authlogic'
gem 'scrypt', '~> 3.0'

# API/Controllers
gem 'responders', '~> 3.0'

# File uploads
gem 'kt-paperclip'

# Utilities
gem 'nokogiri', '~> 1.15'
gem 'htmlentities'
gem 'will_paginate'

# Operations
gem 'dotenv-rails', groups: [:development, :test]
gem 'lograge'
gem 'invisible_captcha'
gem 'exception_notification'

# Ruby 3.4+ stdlib gems now need to be explicit
gem 'bigdecimal'
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
