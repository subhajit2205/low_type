# frozen_string_literal: true

require_relative '../expressions/type_expression'
require_relative '../proxies/return_proxy'
require_relative '../queries/type_query'

module Low
  module TypeAccessors
    def type_reader(named_expressions)
      named_expressions.each do |name, exp|
        last_caller = caller_locations(1, 1).first
        file_path = last_caller.path
        start_line = last_caller.lineno
        scope = "#{self}##{name}"

        type_expression = cast_type_expression(exp)
        return_proxy = ::Lowkey::ReturnProxy.new(type_expression:, name:, file_path:, start_line:, scope:)

        @low_methods[name] = ::Lowkey::MethodProxy.new(file_path:, start_line:, scope:, name:, return_proxy:)

        define_method(name) do
          method_proxy = self.class.low_methods[name]
          value = instance_variable_get("@#{name}")
          type_expression.validate!(value:, proxy: method_proxy.return_proxy)
          value
        end
      end
    end

    def type_writer(named_expressions) # rubocop:disable Metrics/AbcSize
      named_expressions.each do |name, expression|
        last_caller = caller_locations(1, 1).first
        file_path = last_caller.path
        start_line = last_caller.lineno
        scope = "#{self}##{name}"

        param_proxies = [ParamProxy.new(expression: cast_type_expression(expression), name:, type: :hashreq, file_path:, start_line:, scope:)]
        @low_methods["#{name}="] = ::Lowkey::MethodProxy.new(file_path:, start_line:, scope:, name:, param_proxies:)

        define_method("#{name}=") do |value|
          method_proxy = self.class.low_methods["#{name}="]
          method_proxy.param_proxies.first.expression.validate!(value:, proxy: method_proxy.param_proxies.first)
          instance_variable_set("@#{name}", value)
        end
      end
    end

    def type_accessor(named_expressions)
      named_expressions.each do |name, expression|
        type_reader({ name => expression })
        type_writer({ name => expression })
      end
    end

    private

    def cast_type_expression(expression)
      if expression.is_a?(::Expressions::Expression)
        expression
      elsif ::Low::TypeQuery.type?(expression)
        TypeExpression.new(type: expression)
      end
    end
  end
end
