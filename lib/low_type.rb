# frozen_string_literal: true

require 'lowkey'

require_relative 'adapters/adapter_loader'
require_relative 'definitions/redefiner'
require_relative 'definitions/type_accessors'
require_relative 'expressions/expressions'
require_relative 'queries/file_parser'
require_relative 'queries/file_query'
require_relative 'syntax/syntax'
require_relative 'types/complex_types'

module LowType
  # We do as much as possible on class load rather than on instantiation to be thread-safe and efficient.
  def self.included(klass) # rubocop:disable Metrics/AbcSize
    require_relative 'syntax/union_types' if LowType.config.union_type_expressions

    class << klass
      def low_methods
        @low_methods ||= {}
      end
    end

    file_path = Low::FileQuery.file_path(klass:)
    return unless File.exist?(file_path)

    file_proxy = Lowkey.load(file_path:)

    klass.extend Low::TypeAccessors
    klass.include Low::Types
    klass.include Low::Expressions
    klass.prepend Low::Redefiner.redefine(method_nodes: file_proxy.instance_methods, class_proxy: file_proxy.class_proxy, klass:, file_path:)
    klass.singleton_class.prepend Low::Redefiner.redefine(method_nodes: file_proxy.class_methods, class_proxy: file_proxy.class_proxy, file_path:)

    if (adapter = Low::Adapter::Loader.load(klass:, file_proxy:, file_path:))
      adapter.process
      klass.prepend Low::Adapter::Methods
    end
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
      @config ||= config.new(true, :error, :type, 100, false, true)
    end

    def configure
      yield(config)
    end
  end
end
