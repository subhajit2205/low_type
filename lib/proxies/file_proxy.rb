# frozen_string_literal: true

module Low
  class FileProxy
    attr_reader :path, :scope
    attr_accessor :start_line, :end_line

    def initialize(path:, scope:, start_line:, end_line: nil)
      @path = path
      @start_line = start_line
      @end_line = end_line || start_line
      @scope = scope
    end

    def lines?
      start_line && end_line
    end
  end
end
