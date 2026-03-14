# frozen_string_literal: true

require_relative '../expressions/type_expression'
require_relative '../proxies/return_proxy'
require_relative '../proxies/param_proxy'
require_relative '../queries/type_query'

module Low
  module TypeAccessors
    def type_reader(named_expressions)
      named_expressions.each do |name, exp|
        last_caller = caller_locations(1, 1).first

        file_path = last_caller.path
        start_line = last_caller.lineno
        scope = "#{self}##{name}"

        expression = cast_type_expression(exp)
        proxy = ::Lowkey::ReturnProxy.new(file_path: file_path, start_line: start_line, scope: scope, name: name, expression: expression, source: nil)

        define_method(name) do
          value = instance_variable_get("@#{name}")
          expression.validate!(value:, proxy:)
          value
        end
      end
    end

    def type_writer(named_expressions)
      named_expressions.each do |name, expression|
        last_caller = caller_locations(1, 1).first

        file_path = last_caller.path
        start_line = last_caller.lineno
        scope = "#{self}##{name}"

        expression = cast_type_expression(expression)
        proxy = ::Lowkey::ParamProxy.new(file_path: file_path, start_line: start_line, scope: scope, name: name, expression: expression, type: :key_req, source: nil)

        define_method("#{name}=") do |value|
          expression.validate!(value:, proxy:)
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
      elsif TypeQuery.type?(expression)
        TypeExpression.new(type: expression)
      end
    end
  end
end
