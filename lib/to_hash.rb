class Array
  def to_hash
    self.inject({}) { |h, nvp| h[nvp[0]] = nvp[1]; h }
  end
end
