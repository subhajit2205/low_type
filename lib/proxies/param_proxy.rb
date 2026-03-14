# frozen_string_literal: true

require 'lowkey'

require_relative '../interfaces/error_handling'
require_relative '../types/error_types'

module ::Lowkey
  class ParamProxy
    include ::Low::ErrorHandling

    attr_reader :file_path, :start_line, :scope
     
    def initialize(file_path: nil, start_line: nil, scope: nil, name:, type:, expression: nil, source: nil, **kwargs)
      @file_path = file_path
      @start_line = start_line
      @scope = scope
      @name = name
      @type = type
      @expression = expression
      @source = source

      kwargs.each do |key, value|
       instance_variable_set("@#{key}", value)
      end
    end

    def error_type
      ::Low::ArgumentTypeError
    end

    def error_message(value:)
      "Invalid argument type '#{output(value:)}' for parameter '#{@name}'. Valid types: '#{@expression.valid_types}'"
    end
  end
end
