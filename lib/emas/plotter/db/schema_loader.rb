module EMAS
  module Plotter
    module DB
      class SchemaLoader
        attr_reader :database

        def initialize(database)
          @database = database
        end

        def load_schema
          create_database_tables
        end

        private

        def create_database_tables
          create_experiments_table
          create_results_table
          create_reproductions_per_node_table
          create_reproductions_per_second_table
        end

        def create_experiments_table
          database.create_table :experiments do
            primary_key :id
            column      :name,        :string
            column      :nodes_count, :integer
          end
        end

        def create_results_table
          database.create_table :results do
            primary_key :id
            foreign_key :experiment_id, :experiments
            column      :node,          :string
            column      :island,        :string
            column      :metric,        :string
            column      :second,        :integer
            column      :value,         :float
          end
        end

        def create_reproductions_per_node_table
          database.create_table :reproductions_per_node do
            primary_key :id
            foreign_key :experiment_id, :experiments
            column      :node,          :string
            column      :second,        :integer
            column      :value,         :float
          end
        end

        def create_reproductions_per_second_table
          database.create_table :reproductions_per_second do
            primary_key :id
            foreign_key :experiment_id, :experiments
            column      :node,          :string
            column      :second,        :integer
            column      :value,         :float
          end
        end
      end
    end
  end
end
