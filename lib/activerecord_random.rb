class ActiveRecord::Base
  def self.random
    # self.offset((self.count * rand).to_i).first
		# self.order('RANDOM()').first # postgres/sqlite
		self.order('RAND()').first # mysql
  end
end
