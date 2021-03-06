# frozen_string_literal: true

require_relative '../config/game/g_18_al'
require_relative 'base'
require_relative 'company_price_50_to_150_percent'
require_relative 'revenue_4d'
require_relative 'terminus_check'

module Engine
  module Game
    class G18AL < Base
      load_from_json(Config::Game::G18AL::JSON)
      AXES = { x: :number, y: :letter }.freeze

      GAME_LOCATION = 'Alabama, USA'
      GAME_RULES_URL = 'http://www.diogenes.sacramento.ca.us/18AL_Rules_v1_64.pdf'
      GAME_DESIGNER = 'Mark Derrick'
      GAME_END_CHECK = { bankrupt: :immediate, stock_market: :current_or, bank: :current_or }.freeze

      EVENTS_TEXT = Base::EVENTS_TEXT.merge('remove_tokens' => ['Remove Tokens', 'Coal Field token removed']).freeze

      ROUTE_BONUSES = %i[atlanta_birmingham mobile_nashville].freeze

      include CompanyPrice50To150Percent
      include Revenue4D
      include TerminusCheck

      def route_bonuses
        ROUTE_BONUSES
      end

      def setup
        setup_company_price_50_to_150_percent

        @corporations.each do |corporation|
          corporation.abilities(:assign_hexes) do |ability|
            ability.description = "Historical objective: #{get_location_name(ability.hexes.first)}"
          end
        end
      end

      def operating_round(round_num)
        Round::Operating.new(self, [
          Step::Bankrupt,
          Step::DiscardTrain,
          Step::G18AL::Assign,
          Step::G18AL::BuyCompany,
          Step::HomeToken,
          Step::SpecialTrack,
          Step::G18AL::Track,
          Step::G18AL::Token,
          Step::Route,
          Step::Dividend,
          Step::SingleDepotTrainBuyBeforePhase4,
          [Step::BuyCompany, blocks: true],
        ], round_num: round_num)
      end

      def stock_round
        Round::Stock.new(self, [
          Step::DiscardTrain,
          Step::G18AL::BuySellParShares,
        ])
      end

      def revenue_for(route)
        # Mobile and Nashville should not be possible to pass through
        ensure_termini_not_passed_through(route, %w[A4 Q2])

        revenue = adjust_revenue_for_4d_train(route, super)

        route.corporation.abilities(:hexes_bonus) do |ability|
          revenue += route.stops.sum { |stop| ability.hexes.include?(stop.hex.id) ? ability.amount : 0 }
        end

        route_bonuses.each do |type|
          revenue += route_bonus(route, type)
        end

        revenue
      end

      def routes_revenue(routes)
        # Ensure we only get each route_bonus at most one time
        total_revenue = super
        route_bonuses.each do |type|
          bonus_amount = routes.first.corporation.abilities(&:amount)
          times_received = routes.count { |r| route_bonus(r, type).positive? }

          total_revenue -= bonus_amount * (times_received - 1) if times_received > 1
        end if routes.any?
        total_revenue
      end

      def event_remove_tokens!
        @corporations.each do |corporation|
          corporation.abilities(:hexes_bonus) do |a|
            @log << "#{corporation.name} removes: #{a.description}"
            corporation.remove_ability(a)
          end
        end
      end

      def get_location_name(hex_name)
        @hexes.find { |h| h.name == hex_name }.location_name
      end

      private

      def route_bonus(route, type)
        route.corporation.abilities(type).sum do |ability|
          ability.hexes == (ability.hexes & route.hexes.map(&:name)) ? ability.amount : 0
        end
      end
    end
  end
end
