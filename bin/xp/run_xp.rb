#  Copyright © by INRIA
#
#  Contributors : Webdam Team <webdam.inria.fr>
#       Emilien Antoine <emilien[dot]antoine[@]inria[dot]fr>
#
#   WebdamLog
#
#   Encoding - UTF-8
require_relative 'data_generators'
require_relative '../../lib/webdamlog_runner'

# generate the dataset and start the experiment
def run_xp!
  if ARGV.include?("xp1")
    include WLXP1
    xpfiles = []
    CSV.foreach(get_run_xp_file) do |row|
      xpfiles = row
      p xpfiles
      p xpfiles.class
    end
    runners = []
    xpfiles.each do |f|
      runners << create_wl_runner(f)
      p "#{runners.last.peername} created"
    end
    runners.reverse_each do |runner| 
      runner.run_engine
      p "#{runner.peername} started"
    end
  end
  if ARGV.include?("xp2")
    include WLXP2
    p NB_PEERS
  end
  if ARGV.include?("xp5")
    include WLXP5
    p NB_PEERS
  end
end

include WLRunner
   
# Giving a program file generated from data_generators start the peer given in
# the name of the file using the address found in the program file
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
    else
      raise WLError, "impossible to find the peername given in the end of the program \
filename: #{peername} in the list of peer specified in the program"
    end
  end
  file.close
  return WLRunner.create(peername, pg_file, port, {:ip => ip_addr, :measure => true})
end # def start_peer
  

#run_xp! if __FILE__==$0
create_wl_runner "xp_files/data_gen_xp1_peer1"

#runner = WLRunner.create("peer1""", "xp_files/data_gen_xp1_peer1", 12345, {:ip => "localhost", :measure => true})
#p runner.peername
#runner.tick
#runner.tick
#p runner.budtime