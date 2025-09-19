# frozen_string_literal: true

require 'rails_helper'

describe HomeHelper do
  # Delete this example and add some real ones or delete this file
  it 'is included in the object returned by #helper' do
    included_modules = (class << helper; self; end).send :included_modules
    expect(included_modules).to include(described_class)
  end
end
