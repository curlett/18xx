# frozen_string_literal: true

require_relative '../corporation'

module Engine
  module G18Chesapeake2p
    class Corporation < Corporation
      SHARE_PERCENTS = [30].concat([10] * 7)
    end
  end
end
