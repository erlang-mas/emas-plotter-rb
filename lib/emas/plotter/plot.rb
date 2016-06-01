require 'gnuplot'

module EMAS
  module Plotter
    class Plot
      attr_reader :data_points

      def initialize(data_points)
        @data_points = data_points
      end

      def draw
        draw_plot_from_data_points
      end

      private

      def draw_plot_from_data_points
        Gnuplot.open do |gnuplot|
          Gnuplot::Plot.new(gnuplot) do |plot|
            plot.title  "EMAS"
            plot.ylabel "Reproductions / s"
            plot.xlabel "Nodes count"
            plot.grid

            plot.xrange "[1:]"
            plot.yrange '[0:]'
            plot.nokey

            plot.data << Gnuplot::DataSet.new(data_points[0..1]) do |ds|
              ds.with = "linespoints"
              ds.notitle
            end

            plot.data << Gnuplot::DataSet.new(data_points[0..2]) do |ds|
              ds.with = "errorbars"
              ds.notitle
            end
          end
        end
      end
    end
  end
end
