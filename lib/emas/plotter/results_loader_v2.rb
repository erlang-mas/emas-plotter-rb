module EMAS
  module Plotter
    class ResultsLoader
      METRICS = %w(reproduction migration node_migration fitness).freeze

      METRIC_PATH_REGEX = /\A.*\/(.*)\/(.*)\/(.*)\/(.*)\/(.*)\z/

      attr_reader :database, :results_dir

      def initialize(database, results_dir)
        @database = database
        @results_dir = results_dir
      end

      def load_results
        database.transaction do
          metric_paths.each do |metric_path|
            process_metric_file metric_path
            progress_bar.increment
          end
        end
      end

      private

      def process_metric_file(metric_path)
        match = METRIC_PATH_REGEX.match(metric_path)
        meta_data = match[1..-1]

        File.readlines(metric_path).each do |raw_entry|
          entry = meta_data + raw_entry.strip.split(',')
          create_result entry
        end
      end

      def create_result(entry)
        database[:results].insert entry.unshift(nil)
      end

      def metric_paths
        @metric_paths ||= collect_metric_paths
      end

      def collect_metric_paths
        METRICS.flat_map { |metric| Dir["#{results_dir}/**/*/#{metric}"] }
      end

      def progress_bar
        @progress_bar ||= ProgressBar.create(
          total:  metric_paths.count,
          format: '%a %e %P% Processed: %c from %C'
        )
      end
    end
  end
end

# RESULTS:
# experiment node population second value

# {
#   10 => [ # <- num nodes
#     [1, 2, 3, 4, 5, 6, 7, 8, 9, 10], # <- seconds
#     [12.0, 4.6, 3.6, 1.1, 0.5, 0.05, 0.05, 0.05, 0.05, 0.05] # <- fitness
#   ],
#
#   20 => [
#     [1, 2, 3, 4, 5, 6, 7, 8, 9, 10],
#     [12.0, 4.6, 3.6, 1.1, 0.5, 0.05, 0.05, 0.05, 0.05, 0.05]
#   ],
#
#   ...
#
#   100 => [
#     [1, 2, 3, 4, 5, 6, 7, 8, 9, 10],
#     [12.0, 4.6, 3.6, 1.1, 0.5, 0.05, 0.05, 0.05, 0.05, 0.05]
#   ]
# }
