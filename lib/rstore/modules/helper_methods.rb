# encoding: utf-8

module RStore
  module HelperMethods

    # Calulate primary key from schema
    def p_key schema
      schema.map do |(col_name, col_properties)|
        col_name  if col_properties[:primary_key] == true
      end.compact.first
    end

  end
end
