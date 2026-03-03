# frozen_string_literal: true

require 'expressions'
require 'lowkey'

require_relative '../expressions/expression_helpers'
require_relative '../expressions/type_expression'
require_relative '../expressions/value_expression'
require_relative '../syntax/syntax'
require_relative '../types/complex_types'
require_relative '../types/status'

module Low
  class Evaluator
    using ::LowType::Syntax

    include ExpressionHelpers
    include Types

    def evaluate(proxy:)
      eval(proxy.value, binding, proxy.file_path, proxy.start_line) # rubocop:disable Security/Eval
    end

    class << self
      def type_expression_with_value(type:)
        TypeExpression.new(default_value: ValueExpression.new(value: type))
      end

      def load_method_expressions(method_proxy:)
        load_param_proxy_expressions(method_proxy:)
        load_return_proxy_expression(return_proxy: method_proxy.return_proxy) if method_proxy.return_proxy
      end

      def load_param_proxy_expressions(method_proxy:)
        method_proxy.tagged_params(:value).each do |param_proxy|
          name = param_proxy.name
          type = param_proxy.type

          # Not a security risk because the code comes from a trusted source; the file that included lowtype.
          value = self.new.evaluate(proxy: param_proxy)

          if value.is_a?(::Expressions::Expression)
            param_proxy.expression = value
          elsif value.instance_of?(Class) && value.name == 'Low::LowDependency'
            param_proxy.expression = value.new(provider_key: name)
          elsif ::Low::TypeQuery.type?(value)
            param_proxy.expression = TypeExpression.new(type: value)
          end
        end
      end

      def load_return_proxy_expression(return_proxy:)
        begin
          # Not a security risk because the code comes from a trusted source; the file that included lowtype.
          expression = self.new.evaluate(proxy: return_proxy)
        rescue NameError
          raise NameError, "Unknown return type '#{return_proxy.value}' for #{return_proxy.scope} at #{return_proxy.file_path}:#{return_proxy.start_line}"
        end

        return_proxy.expression = TypeExpression.new(type: expression) unless expression.is_a?(TypeExpression)
      end
    end
  end
end
