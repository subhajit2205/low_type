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
    include ExpressionHelpers
    include Types
    using LowType::Syntax

    def instance_evaluate(proxy:)
      # Not a security risk because the code comes from a trusted source; the file that included lowtype.
      return nil unless proxy.value
    
      eval(proxy.value, binding, proxy.file_path || __FILE__, proxy.start_line || __LINE__)  # rubocop:disable Security/Eval
    end

    class << self
      def evaluate(method_proxies:)
        require_relative '../syntax/union_types' if LowType.config.union_type_expressions

        method_proxies.each_value do |method_proxy|
          evaluate_param_proxy_expressions(method_proxy:)
          evaluate_return_proxy_expression(return_proxy: method_proxy.return_proxy) if method_proxy.return_proxy
        end
      end

      def evaluate_param_proxy_expressions(method_proxy:)
        begin # rubocop:disable Style/RedundantBegin
          method_proxy.tagged_params(:value).each do |param_proxy|
            next unless param_proxy.value

            # TODO: Evaluate in the binding of the class that included LowType if not a type managed by LowType.
            expression = new.instance_evaluate(proxy: param_proxy)
            param_proxy.expression = cast_type_expression(expression:, method_proxy:)
          end
        rescue NameError
          raise NameError, "Unknown type '#{mp.value}' for #{mp.scope} at #{mp.file_path}:#{mp.start_line}"
        end
      end

      def evaluate_return_proxy_expression(return_proxy:)
        begin
          expression = new.instance_evaluate(proxy: return_proxy)
        rescue NameError
          rp = return_proxy
          raise NameError, "Unknown return type '#{rp.value}' for #{rp.scope} at #{rp.file_path}:#{rp.start_line}"
        end

        expression = TypeExpression.new(type: expression) unless expression.is_a?(TypeExpression)

        return_proxy.expression = expression
      end

      private

      def cast_type_expression(expression:, method_proxy:)
        if expression.is_a?(::Expressions::Expression)
          return expression
        elsif expression.instance_of?(Class) && expression.name == 'Low::Dependency'
          return expression.new(provider_key: method_proxy.name)
        elsif TypeQuery.type?(expression)
          return TypeExpression.new(type: expression)
        end

        nil
      end
    end
  end
end
