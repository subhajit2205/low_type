# frozen_string_literal: true

require_relative '../interfaces/error_interface'
require_relative '../types/error_types'

module Low
  class ReturnProxy < ErrorInterface
    attr_reader :type_expression, :name

    def initialize(type_expression:, name:, file_path:, start_line:, scope:)
      super(file_path:, start_line:, scope:)

      @type_expression = type_expression
      @name = name
    end

    def error_type
      ReturnTypeError
    end

    def error_message(value:)
      "Invalid return type '#{output(value:)}' for method '#{@name}'. Valid types: '#{@type_expression.valid_types}'"
    end
  end
end
