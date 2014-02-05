# Copyright © by INRIA
#
#  Contributors : Webdam Team <webdam.inria.fr>
#       Emilien Antoine <emilien[dot]antoine[@]inria[dot]fr>
#
#   WebdamLog
#
#   Encoding - UTF-8
require_relative '../../lib/webdamlog_runner'
require_relative '../../lib/wlbud/wlerror'
require 'csv'

# Constants 
XP_FILE_DIR = ARGV.first if defined?(ARGV)
XPFILE = "XP_NOACCESS"
NUM_ITER = ARGV[1].to_i if (ARGV[1] != nil)


# Parameters:
# * XP_FILE_DIR : The path to the directory with the data generator
#
# By convention :
# * there should be a CSV file named XP_NOACCESS with the list of peer name to
#   start.
# * the program file name of each peer must be an underscore separated string.
#   The last field must be the peername.
def initialize_peers!
  # parse parameters
  raise "no argument found, expected 2" unless defined?(ARGV)
  raise "WLXP alone is not an experiment, choose one of the xp" unless defined? XPFILE
  raise "first argument must be the directory with program files" if (ARGV[0].nil?)
  raise "second argument must be the number of tick before a source peer dies" if (ARGV[1].nil?)

  # Retrieve program files
  xpfiles = []
  CSV.foreach(get_run_xp_file) do |row|
    xpfiles = row
    p "Start experiments with #{xpfiles}"
  end

  # Create WLRunner objects
  runners = []
  xpfiles.each do |f|
    runners << create_wl_runner(File.join(XP_FILE_DIR,f))
    p "#{runners.last.peername} created"
  end
  
  # Start Webdamlog peers
  runners.each do |runner|
    if runner.peername.include? "source"
      # start in background and die by itself when NUM_ITER ticks has been done
      # on this source node

    elsif runner.peername.include? "master"
      # start in foreground and die when Webdamlog relation done is updated

    else
      # start in background and die when Webdamlog relation done is updated
      runner.run_bg_not_tick
    end
  end

end

# Instantiate a new runner from the pg_file given.
#  peername is supposed to be the last element in the file name splitted by '_'
def create_wl_runner pg_file
  ip_addr = port = ''
  pg_splitted = pg_file.split "_"
  peername = pg_splitted.last
  file = File.new pg_file, "r"
  loop = true
  while loop and line = file.gets
    if(/^peer/.match line and line.include? peername) # find line which contains peer current peer address
      peerline = line.split("=").last.strip
      peerline.slice!(-1) # remove last ;
      ip_addr, port = peerline.split ":"
      loop = false
    end
  end
  file.close
  raise WLError, "impossible to find the peername given in the end of the program \
filename: #{peername} in the list of peer specified in the program" if ip_addr.nil? or port.nil?
  return WLRunner.create(peername, pg_file, port, {:ip => ip_addr, :measure => true})
end # def create_wl_runner

def get_run_xp_file  
  file_name = File.join(XP_FILE_DIR, XPFILE)
  raise "expected file #{file_name} does not exists" unless File.exist?(file_name)
  return file_name
end

initialize_peers! if __FILE__==$0