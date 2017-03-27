require_relative 'plots/base_plot'
require_relative 'plots/fitness_plot'
require_relative 'plots/behaviour_plot'

module EMAS
  module Plotter
    module Plots
      def self.for(metric)
        case metric
        when :fitness
          FitnessPlot
        when :agents_count
          FitnessPlot
        else
          BehaviourPlot
        end
      end
    end
  end
end
