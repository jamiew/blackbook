source 'https://rubygems.org'
ruby File.open(File.dirname(__FILE__)+'/.ruby-version', 'rb') { |f| f.read.chomp }

gem 'rails', '~> 8.1.0'
gem 'mysql2'
gem 'puma', '~> 8.0'

# Serves assets and handles compression and caching in front of Puma, inside
# the container. It is what removes the need for nginx to serve static files.
gem 'thruster', require: false

# Assets
gem 'propshaft'

# Performance
gem 'bootsnap', require: false

# Frontend
gem 'haml'

# Auth. bcrypt backs has_secure_password; scrypt stays to verify the hashes
# Authlogic wrote, which cannot be converted. See User#authenticate_legacy_scrypt.
gem 'bcrypt', '~> 3.1'
gem 'scrypt', '~> 3.0'
# Still here only so the specs can build a real Authlogic hash to test against.
gem 'authlogic', require: false

# API/Controllers
gem 'responders', '~> 3.0'

# File uploads. Active Storage is the destination; kt-paperclip stays only
# until every attachment has been backfilled. See lib/tasks/active_storage.rake.
gem 'image_processing', '~> 1.2'
gem 'kt-paperclip'

# Utilities
gem 'nokogiri', '~> 1.15'
gem 'will_paginate'

# Operations
gem 'dotenv-rails', groups: [:development, :test]
gem 'lograge'
gem 'invisible_captcha'
gem 'exception_notification'

# Ruby 3.4+ stdlib gems now need to be explicit
gem 'bigdecimal'
gem 'rexml'

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
  # Deploys the container. See config/deploy.yml.
  gem 'kamal', require: false
end
