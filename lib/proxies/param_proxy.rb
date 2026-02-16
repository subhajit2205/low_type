# frozen_string_literal: true

require_relative '../interfaces/error_interface'
require_relative '../types/error_types'

module Low
  class ParamProxy < ErrorInterface
    attr_reader :expression, :name, :type, :position

    def initialize(expression:, name:, type:, file_path:, start_line:, scope:, position: nil)
      super(file_path:, start_line:, scope:)

      @expression = expression
      @name = name
      @type = type
      @position = position
    end

    def required?
      @expression.required?
    end

    def error_type
      ArgumentTypeError
    end

    def error_message(value:)
      "Invalid argument type '#{output(value:)}' for parameter '#{@name}'. Valid types: '#{@expression.valid_types}'"
    end
  end
end
