module EMAS
  module Plotter
    module Plots
      class BehaviourPlot < BasePlot
        private

        def draw_data_sets(plot)
          metric_name = Utils.humanize(metric).capitalize

          plot.title  "EMAS - #{metric_name.capitalize}"

          plot.ylabel "#{Utils.pluralize(metric_name)} / s"
          plot.xlabel 'Nodes count'

          plot.xrange '[1:]'
          plot.yrange '[0:]'

          plot.data << Gnuplot::DataSet.new(data_sets[0..1]) do |ds|
            ds.with = 'linespoints'
            ds.notitle
          end

          plot.data << Gnuplot::DataSet.new(data_sets[0..2]) do |ds|
            ds.with = 'errorbars'
            ds.notitle
          end
        end
      end
    end
  end
end
