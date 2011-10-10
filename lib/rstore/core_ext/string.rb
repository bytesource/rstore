# encoding: utf-8
class String

  def unquote
    self.gsub(/(^"|"$)/,"").gsub(/""/,'"')
  end

  def is_i?
    !!(self =~ /^[-+]?[0-9,]+$/)
  end

  # Checks if String represents a Float.
  def is_f?
    !!(self =~ /^[-+]?[0-9,]+\.[0-9]+$/)
  end

  def to_num
    if self.is_f?
      self.to_f
    elsif self.is_i?
      self.to_i
    else
    end
  end


  def url?
    # http://daringfireball.net/2010/07/improved_regex_for_matching_urls
    url_regex = /^((?:https?:\/\/|www\d{0,3}[.]|[a-z0-9.\-]+[.][a-z]{2,4}\/)(?:[^\s()<>]+|\(([^\s()<>]+|(\([^\s()<>]+\)))*\))+
                   (?:\(([^\s()<>]+|(\([^\s()<>]+\)))*\)|[^\s`!()\[\]{};:'".,<>?«»“”‘’]))/x

    !!(self =~ url_regex)

  end







end
