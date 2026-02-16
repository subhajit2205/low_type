# frozen_string_literal: true

require_relative '../factories/expression_factory'
require_relative '../proxies/local_proxy'
require_relative '../types/error_types'

module Low
  module Expressions
    def type(type_expression)
      value = type_expression.default_value

      last_caller = caller_locations(1, 1).first
      file_path = last_caller.path
      start_line = last_caller.lineno
      proxy = LocalProxy.new(type_expression:, name: self, file_path:, start_line:, scope: 'local type')

      type_expression.validate!(value:, proxy:)

      return value.value if value.is_a?(ValueExpression)

      value
    rescue NoMethodError
      raise ConfigError, "Invalid type expression, likely because you didn't add 'using LowType::Syntax'"
    end
    alias low_type type

    def value(type)
      ExpressionFactory.type_expression_with_value(type:)
    end
    alias low_value value
  end
end
