module EMAS
  module Plotter
    class Runner
      attr_reader :results_dir

      def initialize(results_dir)
        @results_dir = results_dir
      end

      def run
        $stdout.puts 'Building database'
        database = DB::Builder.new.build_database

        $stdout.puts 'Loading results'
        results_loader = ResultsLoader.new database, results_dir
        results_loader.load_results

        $stdout.puts 'Performing results aggregation'
        data_points = Aggregator.new(database).aggregate

        $stdout.puts 'Plotting'
        plot = Plot.new data_points
        plot.draw
      end
    end
  end
end
