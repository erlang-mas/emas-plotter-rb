require 'thor'

module EMAS
  module Plotter
    class CLI < Thor
      desc 'plot', 'Plots simulation results'
      method_option :db,     type: :string
      method_option :metric, type: :string, default: 'reproduction'
      method_option :output, type: :string

      def plot(results_dir = nil)
        unless results_dir || options[:db]
          $stderr.puts 'You must provide at least results dir or db path'
          exit 1
        end

        runner = Runner.new results_dir, options
        runner.run
      end
    end
  end
end
