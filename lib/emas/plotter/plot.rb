require 'gnuplot'

module EMAS
  module Plotter
    class Plot
      attr_reader :data_points, :metric, :output

      def initialize(data_points, metric, output)
        @data_points = data_points
        @metric = metric
        @output = output
      end

      def draw
        draw_plot_from_data_points
      end

      private

      def draw_plot_from_data_points
        Gnuplot.open do |gnuplot|
          Gnuplot::Plot.new(gnuplot) do |plot|
            metric_name = Utils.humanize(metric).capitalize

            plot.set 'terminal', 'png'
            plot.output output if output

            plot.title  "EMAS - #{metric_name.capitalize}"

            plot.ylabel "#{Utils.pluralize(metric_name)} / s"
            plot.xlabel 'Nodes count'

            plot.grid

            plot.xrange '[1:]'
            plot.yrange '[0:]'
            plot.nokey

            plot.data << Gnuplot::DataSet.new(data_points[0..1]) do |ds|
              ds.with = 'linespoints'
              ds.notitle
            end

            plot.data << Gnuplot::DataSet.new(data_points[0..2]) do |ds|
              ds.with = 'errorbars'
              ds.notitle
            end
          end
        end
      end
    end
  end
end
