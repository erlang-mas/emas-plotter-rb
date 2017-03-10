module EMAS
  module Plotter
    module Plots
      class FitnessPlot < BasePlot
        private

        def draw_data_sets(plot)
          data_sets.each_pair do |nodes_count, data_points|
            plot.data << Gnuplot::DataSet.new(data_points) do |ds|
              ds.with = 'lines'
              ds.title = nodes_count
            end
          end
        end
      end
    end
  end
end
