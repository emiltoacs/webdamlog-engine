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
require_relative '../../lib/wlbud/wlerror'

# generate the dataset and start the experiment
def run_xp!
  if ARGV.include?("xp1")
    include WLXP1
    run_xp_peers
  end
  if ARGV.include?("xp2")
    include WLXP2
    run_xp_peers
  end
  if ARGV.include?("xp3")
    include WLXP2
    run_xp_peers
  end
  if ARGV.include?("xp4")
    include WLXP2
    run_xp_peers
  end
  if ARGV.include?("xp5")
    include WLXP5
    run_xp_peers
  end
end

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
    end
  end
  file.close
  raise WLError, "impossible to find the peername given in the end of the program \
filename: #{peername} in the list of peer specified in the program" if ip_addr.nil? or port.nil?  
  return WLRunner.create(peername, pg_file, port, {:ip => ip_addr, :measure => true})
end # def start_peer

def run_xp_peers
  xpfiles = []
  CSV.foreach(get_run_xp_file) do |row|
    xpfiles = row
    p "Start experiments with #{xpfiles}"
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
  runners.reverse_each do |runner|
    runner.sync_do do
      p "Final tick step of #{runner.peername} : #{runner.budtime}"
    end
  end
end

run_xp! if __FILE__==$0