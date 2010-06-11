class ActiveRecord::Base
  # produce a random row from the database
  # TODO: how to force no caching?
  def self.random
    self.find(:first, :offset => ( self.count * rand ).to_i)
  end
end

