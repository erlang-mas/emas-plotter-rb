require 'ruby-progressbar'

module EMAS
  module Plotter
    class ResultsLoader
      attr_reader :database, :results_dir

      ENTRY_REGEX = {
        experiment: /\A\w{16}\z/,
        node:       /\An\d+-\w+\.zeus\z/,
        island:     /\A<\d+\.\d+\.\d+>\z/,
        metric:     /\A\w+\.txt\z/
      }.freeze

      METRIC_ENTRY_REGEX = /'(.+)'\s+\[(.+),(.+)\]\s+{{.+,(.+),.+},(.+)}/

      def initialize(database, results_dir)
        @database = database
        @results_dir = results_dir
      end

      def load_results
        experiments(results_dir) do |experiment_dir, experiment_name|
          nodes_count = nodes experiment_dir
          experiment_id = create_experiment experiment_name, nodes_count

          nodes(experiment_dir) do |node_dir|
            database.transaction do
              islands(node_dir) do |island_dir|
                metrics(island_dir) do |metric_path|
                  process_metric_file experiment_id, metric_path
                end
              end
            end

            progress_bar.increment
          end
        end
      end

      private

      def experiments(dir, &block)
        traverse dir, ENTRY_REGEX[:experiment], &block
      end

      def nodes(dir, &block)
        traverse dir, ENTRY_REGEX[:node], &block
      end

      def islands(dir, &block)
        traverse dir, ENTRY_REGEX[:island], &block
      end

      def metrics(dir, &block)
        traverse dir, ENTRY_REGEX[:metric], &block
      end

      def traverse(dir, entry_regex)
        entries_count = 0

        Dir.foreach(dir) do |entry|
          next unless entry =~ entry_regex

          entries_count += 1
          entry_path = File.join dir, entry

          yield entry_path, entry if block_given?
        end

        entries_count
      end

      def process_metric_file(experiment_id, metric_path)
        File.readlines(metric_path).each do |metric_entry|
          match = METRIC_ENTRY_REGEX.match metric_entry
          next unless match

          result = normalize_metric_entry match
          create_result experiment_id, result
        end
      end

      def normalize_metric_entry(metric_entry)
        keys = %i(node island metric second value)
        keys.zip(metric_entry[1..5]).to_h
      end

      def create_experiment(experiment_name, nodes_count)
        database[:experiments].insert(
          name:        experiment_name,
          nodes_count: nodes_count
        )
      end

      def create_result(experiment_id, result)
        database[:results].insert experiment_id: experiment_id, **result
      end

      def progress_bar
        @progress_bar ||= ProgressBar.create(
          total:  items_count,
          format: '%a %e %P% Processed: %c from %C'
        )
      end

      def items_count
        @items_count ||= begin
          counter = 0

          experiments(results_dir) do |experiment_dir|
            counter += nodes experiment_dir
          end

          counter
        end
      end
    end
  end
end
