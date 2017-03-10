module EMAS
  module Plotter
    module Aggregators
      class BehaviourAggregator < BaseAggregator
        def aggregate
          clear_aggregation_tables
          aggregate_behaviour_per_node
          normalize_seconds
          aggregate_behaviour_per_second
          build_data_points
        end

        private

        def clear_aggregation_tables
          database[:behaviour_per_node].truncate
          database[:behaviour_per_second].truncate
        end

        def aggregate_behaviour_per_node
          database[:behaviour_per_node].import(
            [:experiment_id, :node, :second, :value],
            behaviour_per_node_aggregation
          )
        end

        def behaviour_per_node_aggregation
          database[:results]
            .where(metric: metric.to_s)
            .group(:experiment_id, :second, :node).select(:experiment_id, :node, :second)
            .select_append { sum(value).as(value) }
            .having { { count(population) => 24 } }
        end

        def normalize_seconds
          align_first_seconds
          trim_boundary_seconds
        end

        def align_first_seconds
          first_seconds.each do |second|
            database[:behaviour_per_node]
              .where(experiment_id: second[:experiment_id])
              .update(second: Sequel.expr(:second) - second[:second])
          end
        end

        def first_seconds
          @first_seconds ||= begin
            database[:behaviour_per_node]
              .group(:experiment_id)
              .select(:experiment_id)
              .select_append { min(second).as(second) }.to_a
          end
        end

        def trim_boundary_seconds
          database[:behaviour_per_node]
            .where(Sequel.~(second: 15..75))
            .delete
        end

        def aggregate_behaviour_per_second
          database[:behaviour_per_second].import(
            [:experiment_id, :node, :second, :value],
            behaviour_per_second_aggregation
          )
        end

        def behaviour_per_second_aggregation
          database[:behaviour_per_node]
            .join(
              :behaviour_per_node___next_behaviour_per_node,
              next_behaviour_per_node__experiment_id: :experiment_id,
              next_behaviour_per_node__node: :node
            ) do |next_behaviour_per_node, behaviour_per_node|
              this_second = Sequel.qualify behaviour_per_node, :second
              next_second = Sequel.qualify(next_behaviour_per_node, :second) - 1

              { this_second => next_second }
            end
            .select(
              :behaviour_per_node__experiment_id,
              :behaviour_per_node__node,
              :next_behaviour_per_node__second
            ).select_append do
              this_value = Sequel.qualify(:behaviour_per_node, :value)
              next_value = Sequel.qualify(:next_behaviour_per_node, :value)

              (next_value - this_value).as :value
            end
        end

        def build_data_points
          average_behaviour_per_second_with_std.map(&:values).transpose
        end

        def average_behaviour_per_second
          @average_behaviour_per_second ||= begin
            database[:experiments]
              .join(:behaviour_per_second, experiment_id: :id)
              .group(:nodes_count)
              .select(:nodes_count)
              .select_append { avg(:value).as(:average_reproductions) }
          end
        end

        def average_behaviour_per_second_with_std
          @average_behaviour_per_second_with_std ||= begin
            results = average_behaviour_per_second.to_a

            results.each do |result|
              result[:standard_deviation] = calculate_standard_deviation result
            end

            results
          end
        end

        def calculate_standard_deviation(result)
          result =
            database[:experiments]
            .join(:behaviour_per_second) do |behaviour_per_second, experiment|
              { Sequel.qualify(experiment, :id) => Sequel.qualify(behaviour_per_second, :experiment_id) }
            end
            .select(:nodes_count)
            .select_append do
              sum((value - result[:average_reproductions]) * (value - result[:average_reproductions])).as(:standard_deviation)
            end
            .select_append do
              count(value).as(samples_count)
            end
            .group(:nodes_count)

          result = result.to_a.first
          (result[:standard_deviation] / result[:samples_count])**(1.0 / 2)
        end
      end
    end
  end
end
