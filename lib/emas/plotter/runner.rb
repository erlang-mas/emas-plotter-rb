module EMAS
  module Plotter
    class Runner
      attr_reader :results_dir

      def initialize(results_dir)
        @results_dir = results_dir
      end

      def run
        database_builder = DB::Builder.new

        database = database_builder.build_database

        results_loader = ResultsLoader.new database, results_dir
        results_loader.load_results
      end
    end
  end
end
