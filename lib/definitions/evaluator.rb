# frozen_string_literal: true

require 'expressions'
require 'lowkey'

require_relative '../expressions/expression_helpers'
require_relative '../expressions/type_expression'
require_relative '../syntax/syntax'
require_relative '../types/complex_types'
require_relative '../types/status'

module Low
  # Evaluate code stored in strings into constants and values.
  # ┌────────┐     ┌─────────┐     ┌─────────────┐     ┌─────────┐     ┌─────────┐
  # │ Lowkey │     │ Proxies │     │ Expressions │     │ LowType │     │ Methods │
  # └────┬───┘     └────┬────┘     └──────┬──────┘     └────┬────┘     └────┬────┘
  #      │              │                 │                 │               │
  #      │ Parses AST   │                 │                 │               │
  #      ├─────────────►│                 │                 │               │
  #      │              │                 │                 │               │
  #      │              │ Stores          │                 │               │
  #      │              ├────────────────►│                 │               │
  #      │              │                 │                 │               │
  #      │              │                 │ Evaluates <-- YOU ARE HERE.     |
  #      │              │                 │◄────────────────┤               │
  #      │              │                 │                 │               │
  #      │              │                 │                 │ Redefines     │
  #      │              │                 │                 ├──────────────►│
  #      │              │                 │                 │               │
  #      │              │                 │ Validates       │               │
  #      │              │                 │◄┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┤
  #      │              │                 │                 │               │
  class Evaluator
    using ::LowType::Syntax

    include ExpressionHelpers
    include Types

    def instance_evaluate(proxy:)
      # Not a security risk because the code comes from a trusted source; the file that included lowtype.
      eval(proxy.value, binding, proxy.file_path, proxy.start_line) # rubocop:disable Security/Eval
    end

    class << self
      def evaluate(method_proxies:)
        method_proxies.values.each do |method_proxy|
          evaluate_param_proxy_expressions(method_proxy:)
          evaluate_return_proxy_expression(return_proxy: method_proxy.return_proxy) if method_proxy.return_proxy
        end
      end

      def evaluate_param_proxy_expressions(method_proxy:)
        begin
          method_proxy.tagged_params(:value).each do |param_proxy|
            name = param_proxy.name
            type = param_proxy.type

            expression = self.new.instance_evaluate(proxy: param_proxy)

            if expression.is_a?(::Expressions::Expression)
              param_proxy.expression = expression
            elsif expression.instance_of?(Class) && expression.name == 'Low::LowDependency'
              param_proxy.expression = expression.new(provider_key: name)
            elsif ::Low::TypeQuery.type?(expression)
              param_proxy.expression = TypeExpression.new(type: expression)
            end
          end
        rescue NameError
          raise NameError, "Unknown type '#{method_proxy.value}' for #{method_proxy.scope} at #{method_proxy.file_path}:#{method_proxy.start_line}"
        end
      end

      def evaluate_return_proxy_expression(return_proxy:)
        begin
          expression = self.new.instance_evaluate(proxy: return_proxy)
        rescue NameError
          raise NameError, "Unknown return type '#{return_proxy.value}' for #{return_proxy.scope} at #{return_proxy.file_path}:#{return_proxy.start_line}"
        end

        expression = TypeExpression.new(type: expression) unless expression.is_a?(TypeExpression)

        return_proxy.expression = expression
      end
    end
  end
end
