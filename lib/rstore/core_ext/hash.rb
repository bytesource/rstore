# encoding: utf-8

class Hash

  def include_pairs? hash
    if hash.empty?
      return false
    else
      hash.all? { |key, val| self[key] == val }
    end
  end

end
