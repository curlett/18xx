# frozen_string_literal: true

require_relative '../share_bundle'
require_relative '../share_pool'

module Engine
  module G18Chesapeake
    class SharePool < SharePool
      def buy_shares(entity, shares, exchange: nil, exchange_price: nil)
        if @game.players.size == 2
          bundle = shares.to_bundle
          corporation = bundle.corporation

          return super unless corporation.floated?
          return super if entity == corporation.owner

          removed_share = @shares_by_corporation[corporation].last
          @shares_by_corporation[corporation].delete(removed_share)
          corporation.num_deleted_shares += 1

          if bundle.shares.first == removed_share
            @log << "#{entity.name} uses their buy action to remove the last "\
                    "share of #{corporation.name} from the game"
            return
          else
            @log << "1 share of #{corporation.name} is removed from the game"
          end
        end

        super
      end
    end
  end
end
