# http://pastie.caboo.se/10707
class Hash
  # Usage { :a => 1, :b => 2, :c => 3}.except(:a) -> { :b => 2, :c => 3}
  def except(*keys)
    self.reject { |k,v|
      keys.include? k.to_sym
    }
  end

  # Usage { :a => 1, :b => 2, :c => 3}.only(:a) -> {:a => 1}
  def only(*keys)
    self.dup.reject { |k,v|
      !keys.include? k.to_sym
    }
  end
end

class Array
  def shuffle
    dup.shuffle!
  end

  def shuffle!
    each_index do |i|
      j = rand(length-i) + i
      self[j], self[i] = self[i], self[j]
    end
  end
end

# fix the partials in action mailer tempates that still haven't been fixed
# http://dev.rubyonrails.org/ticket/2926
module ActionMailer
  class Base
    def self.controller_path
      ''
    end
  end
end

# http://www.ruby-forum.com/topic/75258
module Kernel
private
   def this_method
     caller[0] =~ /`([^']*)'/ and $1
   end
end
