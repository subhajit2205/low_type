# frozen_string_literal: true

module Low
  class MethodProxy
    attr_reader :file_path, :start_line, :scope
    attr_reader :name, :params, :return_proxy

    def initialize(file_path:, start_line:, scope:, name:, param_proxies: [], return_proxy: nil)
      @file_path = file_path
      @start_line = start_line
      @scope = scope

      @name = name
      @param_proxies = param_proxies
      @return_proxy = return_proxy
    end
  end
end
