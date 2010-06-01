# Be sure to restart your server when you modify this file.

# Your secret key for verifying cookie session data integrity.
# If you change this key, all old sessions will become invalid!
# Make sure the secret is at least 30 characters and all random,
# no regular words or you'll be exposed to dictionary attacks.
ActionController::Base.session = {
  :key         => '_blackbook_session',
  :secret      => '3bab1b6d3f942f073e2ce160f1bc0c135e67bbfcd5c11cd3e610773da526a6cc58f4659339ce0cc3d43c80dcd2a62d43814006f793a147d5304f1f2fcb655b06'
}

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rake db:sessions:create")
# ActionController::Base.session_store = :active_record_store
