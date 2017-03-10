require_relative 'aggregators/base_aggregator'
require_relative 'aggregators/fitness_aggregator'
require_relative 'aggregators/behaviour_aggregator'

module EMAS
  module Plotter
    module Aggregators
      def self.for(metric)
        case metric
        when :fitness
          FitnessAggregator
        else
          BehaviourAggregator
        end
      end
    end
  end
end
