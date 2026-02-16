# frozen_string_literal: true

module Low
  class MethodProxy
    attr_reader :name, :params, :return_proxy

    def initialize(file_path:, start_line:, scope:, name:, params: [], return_proxy: nil)
      super(file_path:, start_line:, scope:)

      @name = name
      @params = params
      @return_proxy = return_proxy
    end
  end
end
