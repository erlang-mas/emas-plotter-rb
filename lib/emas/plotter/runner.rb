require 'logger'

module EMAS
  module Plotter
    class Runner
      # METRICS = %i(fitness reproduction migration node_migration)
      METRICS = %i(agents_count)

      attr_reader :results_dir, :options

      def initialize(results_dir, options = {})
        @results_dir = results_dir
        @options = options
      end

      def run
        logger.info 'Preparing database'
        database = prepare_database

        METRICS.each do |metric|
          logger.info "[#{metric}] Peforming results aggregation"
          data_sets = Aggregators.for(metric).new(database, metric).aggregate

          logger.info "[#{metric}] Plotting"
          Plots.for(metric).new(data_sets, metric, output_dir).draw
          logger.info 'Done'
        end

        logger.info 'Done'
      end

      private

      def prepare_database
        return Sequel.sqlite db_path if db_path
        database = DB::Builder.new.build_database
        ResultsLoader.new(database, results_dir).load_results
        database
      end

      def db_path
        options[:db]
      end

      def output_dir
        options[:output]
      end

      def logger
        @logger ||= Logger.new STDOUT
      end
    end
  end
end
