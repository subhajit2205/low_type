# frozen_string_literal: true

require 'lowkey'

require_relative '../interfaces/error_handling'
require_relative '../types/error_types'

module ::Lowkey
  class ReturnProxy
    include ::Low::ErrorHandling

    attr_accessor :expression, :value
    attr_reader :file_path, :start_line, :scope, :name
    
    def initialize(file_path: nil, start_line: nil, scope: nil, name:, expression: nil, value: nil, source: nil)
     @file_path = file_path
     @start_line = start_line
     @scope = scope
     @name = name
     @expression = expression
     @value = value
     @source = source
    end

    def error_type
      ::Low::ReturnTypeError
    end

    def error_message(value:)
      "Invalid return type '#{output(value:)}' for method '#{@name}'. Valid types: '#{@expression.valid_types}'"
    end
  end
end
