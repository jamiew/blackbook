class Object
  def useful?; true end
  def useless?; false end
end

class NilClass
  def useful?; false end
  def useless?; true end
end

class String
  def useful?
    ! self.blank?
  end
  
  def useless?
    ! self.useful?
  end
end
