# frozen_string_literal: true

require 'lowkey'

require_relative 'adapters/adapter_loader'
require_relative 'definitions/redefiner'
require_relative 'definitions/type_accessors'
require_relative 'expressions/expression_helpers'
require_relative 'queries/file_query'
require_relative 'syntax/syntax'
require_relative 'types/complex_types'

# Architecture:
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
#      │              │                 │ Evaluates       │               │
#      │              │                 │◄────────────────┤               │
#      │              │                 │                 │               │
#      │              │                 │                 │ Redefines     │
#      │              │                 │                 ├──────────────►│
#      │              │                 │                 │               │
#      │              │                 │ Validates       │               │
#      │              │                 │◄┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┤
#      │              │                 │                 │               │
module LowType
  # We do as much as possible on class load rather than on object instantiation to be thread-safe and efficient.
  def self.included(klass)
    file_path = Low::FileQuery.file_path(klass:)
    file_proxy = Lowkey.load(file_path)
    class_proxy = file_proxy[klass.name]

    Low::Evaluator.evaluate(method_proxies: class_proxy.keyed_methods)

    klass.include Low::ExpressionHelpers
    klass.extend Low::ExpressionHelpers
    klass.extend Low::TypeAccessors
    klass.extend Low::Types

    klass.prepend Low::Redefiner.redefine(method_proxies: class_proxy.instance_methods, class_proxy:)
    klass.singleton_class.prepend Low::Redefiner.redefine(method_proxies: class_proxy.class_methods, class_proxy:)

    Low::Adapter::Loader.load(klass:, class_proxy:)
  end

  class << self
    def config
      config = Struct.new(
        :type_checking,
        :error_mode,
        :output_mode,
        :output_size,
        :deep_type_check,
        :union_type_expressions
      )
      @config ||= config.new(true, :error, :type, 100, true, true)
    end

    def configure
      yield(config)
    end
  end
end
