module EMAS
  module Plotter
    class Runner
      attr_reader :results_dir

      def initialize(results_dir)
        @results_dir = results_dir
      end

      def run
        database = DB::Builder.new.build_database

        results_loader = ResultsLoader.new database, results_dir
        results_loader.load_results

        data_points = Aggregator.new(database).aggregate

        plot = Plot.new data_points
        plot.draw
      end
    end
  end
end
