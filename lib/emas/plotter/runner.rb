module EMAS
  module Plotter
    class Runner
      attr_reader :results_dir

      def initialize(results_dir, options = {})
        @results_dir = results_dir

        @db_path = options[:db]
        @metric  = options[:metric]
      end

      def run
        if @db_path
          $stdout.puts "Restoring results from db file: #{@db_path}"
          database = Sequel.sqlite @db_path
        else
          $stdout.puts 'Building database'
          database = DB::Builder.new.build_database

          $stdout.puts 'Loading results'
          results_loader = ResultsLoader.new database, results_dir
          results_loader.load_results
        end

        $stdout.puts 'Performing results aggregation'
        data_points = Aggregator.new(database, @metric).aggregate

        $stdout.puts 'Plotting'
        plot = Plot.new data_points
        plot.draw
      end
    end
  end
end
