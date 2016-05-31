require 'pry'

module EMAS
  module Plotter
    class Aggregator
      attr_reader :database

      def initialize(database)
        @database = database
      end

      def aggregate
        aggregate_reproductions_per_node
        normalize_seconds
        aggregate_reproductions_per_second
        build_data_points
      end

      private

      def aggregate_reproductions_per_node
        database[:reproductions_per_node].import(
          [:experiment_id, :node, :second, :value],
          reproductions_per_node_aggregation
        )
      end

      def reproductions_per_node_aggregation
        @reproductions_per_node_aggregation ||= begin
          database[:results]
            .where(metric: 'reproduction')
            .group(:experiment_id, :second, :node)
            .select(:experiment_id, :node, :second)
            .select_append { sum(value).as(value) }
            .having { { count(island) => 12 } }
        end
      end

      def normalize_seconds
        align_first_seconds
        trim_boundary_seconds
      end

      def align_first_seconds
        first_seconds.each do |second|
          database[:reproductions_per_node]
            .where(experiment_id: second[:experiment_id])
            .update(second: Sequel.expr(:second) - second[:second])
        end
      end

      def first_seconds
        @first_seconds ||= begin
          database[:reproductions_per_node]
            .group(:experiment_id)
            .select(:experiment_id)
            .select_append { min(second).as(second) }.to_a
        end
      end

      def trim_boundary_seconds
        database[:reproductions_per_second]
          .where(Sequel.~(second: 15..75))
          .delete
      end

      def aggregate_reproductions_per_second
        database[:reproductions_per_second].import(
          [:experiment_id, :node, :second, :value],
          reproductions_per_second_aggregation
        )
      end

      def reproductions_per_second_aggregation
        @reproductions_per_second_aggregation ||= begin
          database[:reproductions_per_node]
            .join(
              :reproductions_per_node___next_reproductions_per_node,
              next_reproductions_per_node__experiment_id: :experiment_id,
              next_reproductions_per_node__node: :node
            ) do |next_reproductions_per_node, reproductions_per_node|
              this_second = Sequel.qualify reproductions_per_node, :second
              next_second = Sequel.qualify(next_reproductions_per_node, :second) - 1

              { this_second => next_second }
            end
            .select(
              :reproductions_per_node__experiment_id,
              :reproductions_per_node__node,
              :next_reproductions_per_node__second
            ).select_append do
              this_value = Sequel.qualify(:reproductions_per_node, :value)
              next_value = Sequel.qualify(:next_reproductions_per_node, :value)

              (next_value - this_value).as :value
            end
        end
      end

      def build_data_points
        average_reproductions_per_second.to_a.map(&:values).transpose
      end

      def average_reproductions_per_second
        @average_reproductions_per_second ||= begin
          database[:experiments]
            .join(:reproductions_per_second, experiment_id: :id)
            .group(:nodes_count)
            .select(:nodes_count)
            .select_append { avg(:value).as(:average_reproductions) }
        end
      end
    end
  end
end