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

  # allows you to use { :val => 'foo' }.val #=> "foo"
  # DANGEROUS. commented out for now as well...
  # def method_missing(key)
  #   has_key?(key) || has_key?(key.to_s) ? self[key] || self[key.to_s] : super
  # end
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


# COMMENTED OUT -- this is also in i76-has_slug and the clash causes drama
# class String
#   def to_slug
#     self.gsub("'", '').gsub(/[^\w]+/, '_').gsub(/^_|_$/, '')
#   end
# end
