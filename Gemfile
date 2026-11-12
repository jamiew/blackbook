source 'https://rubygems.org'
ruby File.open(File.dirname(__FILE__)+'/.ruby-version', 'rb') { |f| f.read.chomp }

gem 'rails', '~> 8.1.0'
gem 'mysql2'
gem 'puma', '~> 8.0'

# ActiveSupport 8.1 breaks on json 3, so hold it on 2.x.
gem 'json', '< 3'

# Serves assets, compression and caching in front of Puma.
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

# API/Controllers
gem 'responders', '~> 3.0'
# Covers read API responses and OPTIONS before routing and beta authentication.
gem 'rack-cors'

# Legacy *_file_name columns stay until the Active Storage backfill finishes.
gem 'image_processing', '~> 2.1'
# image_processing 2.x does not include the configured MiniMagick backend.
gem 'mini_magick'

# Renders docs/*.md with tables and fenced code.
gem 'redcarpet'

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

group :test do
  # Builds legacy scrypt hashes for authentication compatibility specs.
  gem 'authlogic', require: false
end

group :development do
  gem 'ruby-lsp', require: false
  # Deploys the container. See config/deploy.yml.
  gem 'kamal', require: false
end
