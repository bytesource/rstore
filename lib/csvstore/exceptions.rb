# encoding: utf-8

module CSVStore
  # The error thrown when the length of a row does not fit the number of columns in the db table.
  class InvalidRowLengthError < StandardError; end
  class NullNotAllowedError   < StandardError; end

end

