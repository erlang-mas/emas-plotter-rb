require 'logger'

module EMAS
  module Plotter
    class Runner
      attr_reader :results_dir

      def initialize(results_dir, options = {})
        @results_dir = results_dir

        @db_path = options[:db]
        @metric  = options[:metric]
        @output  = options[:output]
      end

      def run
        if @db_path
          logger.info "Restoring results from db file: #{@db_path}"
          database = Sequel.sqlite @db_path
        else
          logger.info 'Building database'
          database = DB::Builder.new.build_database

          logger.info 'Loading results'
          results_loader = ResultsLoader.new database, results_dir
          results_loader.load_results
        end

        logger.info 'Performing results aggregation'
        data_points = Aggregator.new(database, @metric).aggregate

        logger.info 'Plotting'
        plot = Plot.new data_points, @metric, @output
        plot.draw

        logger.info 'Done'
      end

      private

      def logger
        @logger ||= Logger.new STDOUT
      end
    end
  end
end
