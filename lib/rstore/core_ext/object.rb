# encoding: utf-8

class Object

  def boolean_or_nil?
    return true if self.nil?
    !!self == self
  end

end
