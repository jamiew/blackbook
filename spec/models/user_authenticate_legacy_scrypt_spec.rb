require 'rails_helper'

# Every account created before the move off Authlogic has only an scrypt hash.
# If this file goes red, those users cannot log in, so it deliberately builds
# its fixture with Authlogic's own provider rather than trusting a constant.
RSpec.describe User, '#authenticate_legacy_scrypt' do
  let(:password) { 'correct horse' }
  let(:salt)     { 'abc123salt' }

  # How Authlogic wrote crypted_password: encrypt(raw_password, salt).
  let(:scrypt_hash) do
    require "#{Gem::Specification.find_by_name('authlogic').gem_dir}/lib/authlogic/crypto_providers/scrypt"
    Authlogic::CryptoProviders::SCrypt.encrypt(password, salt)
  end

  let(:legacy_user) do
    described_class.create!(
      login: "legacy#{rand(100_000)}",
      email: "legacy#{rand(100_000)}@example.com",
      crypted_password: scrypt_hash,
      password_salt: salt,
      persistence_token: SecureRandom.hex,
      perishable_token: SecureRandom.hex
    )
  end

  it 'accepts the old password' do
    expect(legacy_user.authenticate_legacy_scrypt(password)).to be_truthy
  end

  it 'rejects a wrong password' do
    expect(legacy_user.authenticate_legacy_scrypt('wrong')).to be_falsey
  end

  it 'hashes password then salt, not salt then password' do
    # The reversed order also "works" against a hash built the same wrong way,
    # so assert against a hash Authlogic actually produced.
    expect(SCrypt::Password.new(scrypt_hash) == "#{password}#{salt}").to be true
    expect(SCrypt::Password.new(scrypt_hash) == "#{salt}#{password}").to be false
  end

  it 'logs the user in and rehashes to bcrypt' do
    user = legacy_user
    expect(user.password_digest).to be_blank

    found = described_class.authenticate_by_credentials(user.login, password)

    expect(found).to eq(user)
    expect(user.reload.password_digest).to be_present
    expect(BCrypt::Password.new(user.password_digest) == password).to be true
  end

  it 'uses bcrypt once migrated, and the old hash no longer matters' do
    user = legacy_user
    described_class.authenticate_by_credentials(user.login, password)
    # update_column on purpose: corrupting the old hash is the point, and a
    # validated save would refuse it.
    user.reload.update_column(:crypted_password, 'not-a-valid-hash') # rubocop:disable Rails/SkipsModelValidations

    expect(described_class.authenticate_by_credentials(user.login, password)).to eq(user)
    expect(described_class.authenticate_by_credentials(user.login, 'wrong')).to be_nil
  end

  it 'finds users by email as well as login' do
    user = legacy_user
    expect(described_class.authenticate_by_credentials(user.email, password)).to eq(user)
  end
end
