module EMAS
  module Plotter
    module Plots
      class BasePlot
        attr_reader :data_sets, :metric, :output_dir

        def initialize(data_sets, metric, output_dir)
          @data_sets = data_sets
          @metric = metric
          @output_dir = output_dir
        end

        def draw
          Gnuplot.open do |gnuplot|
            Gnuplot::Plot.new(gnuplot) do |plot|
              plot.set 'terminal', 'png'

              ensure_output_dir
              plot.output output_path

              plot.grid

              draw_data_sets plot
            end
          end
        end

        private

        def draw_data_sets(_plot)
          raise NotImplementedError
        end

        def ensure_output_dir
          FileUtils.mkdir_p output_dir if output_dir
        end

        def output_path
          file_name = "#{metric}.png"
          if output_dir
            File.join output_dir, file_name
          else
            file_name
          end
        end
      end
    end
  end
end
