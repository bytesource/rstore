# encoding: utf-8

require 'csv'

# Wrapper around CSV to avoid name clashes inside RStore::CSV
class CSVWrapper < CSV
end
