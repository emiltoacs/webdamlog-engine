#  Copyright © by INRIA
#
#  Contributors : Webdam Team <webdam.inria.fr>
#       Emilien Antoine <emilien[dot]antoine[@]inria[dot]fr>
#
#   WebdamLog
#
#   Encoding - UTF-8
require_relative '../wlerror'
require 'csv'

module WLBud
  BENCH_FILE_DIR = "bench_files"

  # Wrapper around CSV ruby stdlib to record timesteps during bud ticks.
  class WlMeasure

    attr_reader :measure_file

    def initialize budtime=0, measure_file
      raise WLBud::WLError, "take care to initialize WlMeasure object at tick 0" if budtime != 0
      Dir.mkdir(BENCH_FILE_DIR) unless File.exist?(BENCH_FILE_DIR)
      if measure_file.nil?
        @measure_file = File.new(File.join(BENCH_FILE_DIR,"benchark_time_log_#{@peername}_#{Time.now}"), "a+")
      else
        @measure_file = File.new(File.join(BENCH_FILE_DIR,measure_file), "a+")
      end
      @stats_per_ticks = {}
    end

    def initialize_measures budtime
      raise WLBud::WLError, "negative budtime" if budtime < 0
      raise WLBud::WLError, "measure for this budtime has already been initialize" if @stats_per_ticks.include?(budtime)      
      @stats_per_ticks[budtime] = []
      @beginning_time = Time.now
    end

    def append_measure budtime
      @curr_time = Time.now
      @stats_per_ticks[budtime] << @curr_time - @beginning_time
    end

    def dump_measures budtime
      CSV.open(@measure_file.path, "w", :force_quotes=>true) do |csv|
        @stats_per_ticks.each do |stat_tick|
          csv << stat_tick
        end
      end      
    end # def dump_mesures budtime
  end # class WlMeasure
end # module WLBud