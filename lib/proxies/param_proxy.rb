# frozen_string_literal: true

require_relative '../interfaces/error_interface'
require_relative '../types/error_types'

module LowType
  class ParamProxy < ErrorInterface
    attr_reader :expression, :name, :type, :position

    def initialize(expression:, name:, type:, file:, position: nil)
      super()

      @expression = expression
      @name = name
      @type = type
      @position = position
      @file = file
    end

    def required?
      @expression.default_value == :LOW_TYPE_UNDEFINED
    end

    def error_type
      ArgumentTypeError
    end

    def error_message(value:)
      "Invalid argument type '#{output(value:)}' for parameter '#{@name}'. Valid types: '#{@expression.valid_types}'"
    end
  end
end
