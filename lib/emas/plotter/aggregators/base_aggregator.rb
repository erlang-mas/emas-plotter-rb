module EMAS
  module Plotter
    module Aggregators
      class BaseAggregator
        attr_reader :database, :metric

        def initialize(database, metric)
          @database = database
          @metric = metric
        end

        def aggregate
          raise NotImplementedError
        end
      end
    end
  end
end
