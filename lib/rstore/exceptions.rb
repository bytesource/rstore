# encoding: utf-8

module RStore
  # The error thrown when the length of a row does not fit the number of columns in the db table.
  class InvalidRowLengthError < StandardError; end
  class NullNotAllowedError   < StandardError; end

end

