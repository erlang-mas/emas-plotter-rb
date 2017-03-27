module EMAS
  module Plotter
    module Plots
      class FitnessPlot < BasePlot
        private

        def draw_data_sets(plot)
          plot.title 'EMAS - Best fitness'

          plot.xlabel 'Time [s]'
          plot.ylabel 'Best fitness'

          plot.xrange '[1:]'
          # plot.yrange '[:10]'

        #   plot.set 'key horizontal'
        #   plot.set 'key outside center bottom'
        #   plot.set 'key box 5'
          plot.set 'key inside right bottom'

        #   titles_mapping = {
        #       'nmp_0_0' => 'NMP = 0.0',
        #       'nmp_0_01' => 'NMP = 0.01',
        #       'nmp_0_001' => 'NMP = 0.001',
        #       'nmp_0_0001' => 'NMP = 0.0001',
        #       'nmp_0_0005' => 'NMP = 0.0005'
        #   }

        # mp_0_0   mp_0_001 mp_0_01  mp_0_05  mp_0_1

        #   titles_mapping = {
        #       'mp_0_0' => 'MP = 0.0',
        #       'mp_0_1' => 'MP = 0.1',
        #       'mp_0_01' => 'MP = 0.01',
        #       'mp_0_05' => 'MP = 0.05',
        #       'mp_0_001' => 'MP = 0.001'
        #   }

          titles_mapping = {
              '10_nmp_less' => '10 nodes, reduced NMP',
              'mp_0_0001_nmp_0_00001' => 'MP = 0.0001, NMP = 0.00001'
          }


          # plot.logscale 'y'
          # binding.pry

          data_sets.each_pair do |nodes_count, data_points|
            plot.data << Gnuplot::DataSet.new(data_points) do |ds|
              ds.with = 'lines'
              # ds.title = nodes_count
              case nodes_count
              when Integer
                ds.title = "#{nodes_count} #{nodes_count > 1 ? 'nodes' : 'node'}"
              else
                ds.title = titles_mapping[nodes_count]
              end
            end
          end
        end
      end
    end
  end
end
