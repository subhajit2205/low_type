# frozen_string_literal: true

require_relative '../expressions/value_expression'
require_relative '../factories/proxy_factory'
require_relative '../proxies/method_proxy'
require_relative '../queries/type_query'
require_relative 'repository'

module Low
  # Redefine methods to have their arguments and return values type checked.
  class Redefiner
    class << self
      def redefine(method_nodes:, class_proxy:, klass:, file_path:)
        method_proxies = build_methods(method_nodes:, klass:, file_path:)

        if LowType.config.type_checking
          typed_methods(method_proxies:, class_proxy:, klass:)
        else
          untyped_methods(method_proxies:, class_proxy:, klass:)
        end
      end

      def redefinable?(method_proxy:, class_proxy:, klass:)
        method_has_types?(method_proxy:, class_proxy:, klass:) && method_within_class_bounds?(method_proxy:, class_proxy:, klass:)
      end

      def untyped_args(args:, kwargs:, method_proxy:) # rubocop:disable Metrics/AbcSize
        method_proxy.params.each do |param_proxy|
          value = param_proxy.position ? args[param_proxy.position] : kwargs[param_proxy.name]

          next unless value.nil?
          raise param_proxy.error_type, param_proxy.error_message(value:) if param_proxy.required?

          value = param_proxy.expression.default_value # Default value can still be `nil`.
          value = value.value if value.is_a?(ValueExpression)
          param_proxy.position ? args[param_proxy.position] = value : kwargs[param_proxy.name] = value
        end

        [args, kwargs]
      end

      private

      def build_methods(method_nodes:, klass:, file_path:)
        method_nodes.each do |name, method_node|
          begin # rubocop:disable Style/RedundantBegin
            file = ProxyFactory.file_proxy(path: file_path, node: method_node, scope: "#{klass}##{name}")

            param_proxies = ProxyFactory.param_proxies(method_node:, file:)
            return_proxy = ProxyFactory.return_proxy(method_node:, file:, name: method_node.name)
            method_proxy = MethodProxy.new(name:, params: param_proxies, return_proxy:, file:)

            Repository.save(method: method_proxy, klass:)
          # When we can't parse the method's params or return type then skip it.
          rescue SyntaxError
            next
          end
        end

        Repository.all(klass:)
      end

      def typed_methods(method_proxies:, class_proxy:, klass:) # rubocop:disable Metrics
        Module.new do
          method_proxies.each do |name, method_proxy|
            next unless Low::Redefiner.redefinable?(method_proxy:, class_proxy:, klass:)

            # You are now in the binding of the includer class (`name` is also available here).
            define_method(name) do |*args, **kwargs|
              # Inlined version of Repository.load() for performance increase.
              method_proxy = instance_of?(Class) ? low_methods[name] : self.class.low_methods[name] || Object.low_methods[name]

              method_proxy.params.each do |param_proxy|
                value = param_proxy.position ? args[param_proxy.position] : kwargs[param_proxy.name]
                value = param_proxy.expression.default_value if value.nil? && !param_proxy.required?

                param_proxy.expression.validate!(value:, proxy: param_proxy)
                value = value.value if value.is_a?(ValueExpression)
                param_proxy.position ? args[param_proxy.position] = value : kwargs[param_proxy.name] = value
              end

              if (return_proxy = method_proxy.return_proxy)
                return_value = super(*args, **kwargs)
                return_proxy.type_expression.validate!(value: return_value, proxy: return_proxy)
                return return_value
              end

              super(*args, **kwargs)
            end

            private name if class_proxy.private_start_line && method_proxy.start_line > class_proxy.private_start_line
          end
        end
      end

      def untyped_methods(method_proxies:, class_proxy:, klass:)
        Module.new do
          method_proxies.each do |name, method_proxy|
            next unless Low::Redefiner.redefinable?(method_proxy:, class_proxy:, klass:)

            # You are now in the binding of the includer class (`name` is also available here).
            define_method(name) do |*args, **kwargs|
              # NOTE: Type checking is currently disabled. See 'config.type_checking'.
              method_proxy = instance_of?(Class) ? low_methods[name] : self.class.low_methods[name] || Object.low_methods[name]
              args, kwargs = Low::Redefiner.untyped_args(args:, kwargs:, method_proxy:)
              super(*args, **kwargs)
            end

            private name if class_proxy.private_start_line && method_proxy.start_line > class_proxy.private_start_line
          end
        end
      end

      def method_has_types?(method_proxy:, class_proxy:, klass:)
        if method_proxy.params == [] && method_proxy.return_proxy.nil?
          Low::Repository.delete(name: method_proxy.name, klass:)
          return false
        end

        true
      end

      def method_within_class_bounds?(method_proxy:, class_proxy:, klass:)
        within_bounds = method_proxy.start_line > class_proxy.start_line && method_proxy.end_line <= class_proxy.end_line
        if method_proxy.lines? && class_proxy.lines? && !within_bounds
          Low::Repository.delete(name: method_proxy.name, klass:)
          return false
        end

        true
      end
    end
  end
end
