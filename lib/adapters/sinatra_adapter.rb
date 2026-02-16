# frozen_string_literal: true

require 'prism'

require_relative '../factories/proxy_factory'
require_relative '../interfaces/adapter_interface'
require_relative '../proxies/return_proxy'
require_relative '../types/error_types'

module Low
  module Adapter
    # We don't use https://sinatrarb.com/extensions.html because we need to type check all Ruby methods (not just Sinatra) at a lower level.
    class Sinatra < AdapterInterface
      def initialize(klass:, class_proxy:)
        @klass = klass
        @class_proxy = class_proxy
        @file_path = file_path
      end

      def process # rubocop:disable Metrics/AbcSize
        file_path = @class_proxy.file_proxy.file_path
        method_calls = @class_proxy.method_calls(%i[get post patch put delete options query])

        # Type check return values.
        method_calls.each do |method_call|
          arguments_node = method_call.compact_child_nodes.first
          next unless arguments_node.is_a?(Prism::ArgumentsNode)

          pattern = arguments_node.arguments.first.content
          name = "#{method_node.name.upcase} #{pattern}"
          start_line = method_call.start_line

          next unless (return_proxy = ProxyFactory.return_proxy(method_node: method_call, name:, file_path:, start_line:, scope: pattern))

          route = "#{method_call.name.upcase} #{pattern}"
          params = [ParamProxy.new(expression: nil, name: :route, type: :req, position: 0, file_path:)]
          @klass.low_methods[route] = MethodProxy.new(name: method_call.name, params:, return_proxy:)
        end
      end
    end

    module Methods
      # Unfortunately overriding invoke() is the best way to validate types for now. Though direct it's also very compute efficient.
      # I originally tried an after filter and it mostly worked but it only had access to Response which isn't the raw return value.
      # I suggest that Sinatra provide a hook that allows us to access the raw return value of a route before it becomes a Response.
      def invoke(&block)
        res = catch(:halt, &block)

        low_validate!(value: res) if res

        res = [res] if res.is_a?(Integer) || res.is_a?(String)
        if res.is_a?(::Array) && res.first.is_a?(Integer)
          res = res.dup
          status(res.shift)
          body(res.pop)
          headers(*res)
        elsif res.respond_to? :each
          body res
        end

        nil # avoid double setting the same response tuple twice
      end

      def low_validate!(value:)
        route = "#{request.request_method} #{request.path}"
        if (method_proxy = self.class.low_methods[route]) && (proxy = method_proxy.return_proxy)
          proxy.type_expression.validate!(value:, proxy:)
        end
      end
    end
  end
end
