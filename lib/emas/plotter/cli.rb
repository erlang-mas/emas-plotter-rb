require 'thor'

module EMAS
  module Plotter
    class CLI < Thor
      desc 'plot RESULTS_DIR', 'Plots simulation results'

      def plot(results_dir)
        runner = Runner.new results_dir
        runner.run
      end
    end
  end
end
