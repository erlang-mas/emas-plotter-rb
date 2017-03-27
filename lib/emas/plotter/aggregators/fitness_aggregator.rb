module EMAS
  module Plotter
    module Aggregators
      class FitnessAggregator < BaseAggregator
        def aggregate
          clear_aggregation_tables
          aggregate_fitness_per_second
          normalize_seconds
          build_data_sets
        end

        private

        def clear_aggregation_tables
          database[:metric_per_second].truncate
        end

        def aggregate_fitness_per_second
          database[:metric_per_second].import(
            [:experiment_id, :second, :value],
            fitness_per_second_aggregation
          )
        end

        def fitness_per_second_aggregation
          database[:results]
            .where(metric: metric.to_s)
            .where { value > -10_000_000 }
            .select_group(:experiment_id, :second)
            .select_append { avg(value).as(value) }
        end

        def normalize_seconds
          timestamps_to_seconds
        end

        def timestamps_to_seconds
          first_timestamps.each do |record|
            database[:metric_per_second]
              .where(experiment_id: record[:experiment_id])
              .update(second: Sequel.expr(:second) - record[:second])
          end
        end

        def first_timestamps
          @first_timestamps ||= fetch_first_timestamps
        end

        def fetch_first_timestamps
          database[:metric_per_second]
            .select_group(:experiment_id)
            .select_append { min(second).as(second) }
            .to_a
        end

        def build_data_sets
          data_sets = fetch_data_sets
          data_sets.each_pair do |nodes_count, data_points|
            x, y = data_points.transpose
            # data_sets[nodes_count] = [x, y.map { |y_dp| y_dp.abs + 0.001 }]
            data_sets[nodes_count] = [x, y]
          end
          data_sets
        end

        def fetch_data_sets
          database[:experiments]
            .join(:metric_per_second, experiment_id: :id)
            .select_group(:nodes_count, :second)
            .select_append { avg(value).as(value) }
            .to_hash_groups(:nodes_count, [:second, :value])
        end
      end
    end
  end
end
