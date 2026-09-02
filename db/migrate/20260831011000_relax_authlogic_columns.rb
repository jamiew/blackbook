class RelaxAuthlogicColumns < ActiveRecord::Migration[8.1]
  # Authlogic filled these on every create. Nothing does now, and a user who
  # signs up with bcrypt has no scrypt hash and no session token to store, so
  # NOT NULL makes every new signup fail.
  #
  # The columns stay because existing rows still authenticate through them.
  # See User#authenticate_legacy_scrypt.
  def up
    change_column_null :users, :crypted_password, true
    change_column_null :users, :password_salt, true
    change_column_null :users, :persistence_token, true
  end

  def down
    # Only reversible while no bcrypt-only user exists, which stops being true
    # the moment anyone signs up or logs in after this ships.
    raise ActiveRecord::IrreversibleMigration,
          "Users created after this migration have no scrypt hash, so NOT NULL cannot be restored."
  end
end
