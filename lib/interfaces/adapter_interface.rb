# frozen_string_literal: true

module Low
  class AdapterInterface
    def process
      raise NotImplementedError
    end
  end
end
