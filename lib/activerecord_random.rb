# frozen_string_literal: true

module ActiveRecord
  class Base
    def self.random
      # self.offset((self.count * rand).to_i).first
      # self.order('RANDOM()').first # postgres/sqlite
      order('RAND()').first # mysql
    end
  end
end
