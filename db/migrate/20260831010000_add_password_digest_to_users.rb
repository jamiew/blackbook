class AddPasswordDigestToUsers < ActiveRecord::Migration[8.1]
  # Authlogic stored scrypt hashes in crypted_password. has_secure_password
  # wants bcrypt in password_digest, and scrypt cannot be converted to bcrypt,
  # so both columns coexist. Users move across one at a time, the next time
  # each logs in successfully. See User.authenticate_by_credentials.
  #
  # crypted_password and password_salt stay until nothing is left that only has
  # a scrypt hash. Dropping them early logs those accounts out permanently.
  def change
    add_column :users, :password_digest, :string
  end
end
