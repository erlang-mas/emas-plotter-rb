module EMAS
  module Plotter
    class ResultsLoader
      attr_reader :database, :results_dir

      ENTRY_REGEX = {
        node_count: /\A\d+\z/,
        experiment: /\A\w{16}\z/,
        node:       /\Aemas-\d{2,3}@\w+\z/,
        population: /\A(\<\d+\.\d+\.\d+>)|global\z/,
        metric:     /\A\w+\z/
      }.freeze

      def initialize(database, results_dir)
        @database = database
        @results_dir = results_dir
      end

      def load_results
        node_counts(results_dir) do |nodes_count_dir, nodes_count|
          experiments(nodes_count_dir) do |experiment_dir, experiment|
            experiment_id = create_experiment experiment, nodes_count

            nodes(experiment_dir) do |node_dir, node|
              database.transaction do
                populations(node_dir) do |population_dir, population|
                  metrics(population_dir) do |metric_path, metric|
                    process_metric_file metric_path, experiment_id, node, population, metric
                  end
                end
              end

              progress_bar.increment
            end
          end
        end
      end

      private

      def node_counts(dir, &block)
        traverse dir, ENTRY_REGEX[:node_count], &block
      end

      def experiments(dir, &block)
        traverse dir, ENTRY_REGEX[:experiment], &block
      end

      def nodes(dir, &block)
        traverse dir, ENTRY_REGEX[:node], &block
      end

      def populations(dir, &block)
        traverse dir, ENTRY_REGEX[:population], &block
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

      def process_metric_file(metric_path, experiment_id, node, population, metric)
        File.readlines(metric_path).each do |metric_entry|
          timestamp, value = metric_entry.strip.split(",")
          entry = [node, population, metric, timestamp, value]
          result = normalize_metric_entry entry
          create_result experiment_id, result
        end
      end

      def normalize_metric_entry(metric_entry)
        keys = %i(node population metric second value)
        keys.zip(metric_entry).to_h
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

          node_counts(results_dir) do |nodes_count_dir|
            experiments(nodes_count_dir) do |experiment_dir|
              counter += nodes experiment_dir
            end
          end

          counter
        end
      end
    end
  end
end
