class Fixnum
  def to_time_s(format='%M:%S')
    Time.at(self).gmtime.strftime(format)
  end
end

class Float
  def to_time_s(format='%M:%S')
    Time.at(self).gmtime.strftime(format)
  end
end
