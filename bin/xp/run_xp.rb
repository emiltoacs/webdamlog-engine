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
def run!
  if ARGV.include?("xp1")
    include XP1
    p NB_PEERS
  end
  if ARGV.include?("xp2")
    include XP2
    p NB_PEERS
  end
  if ARGV.include?("xp5")
    include XP5
    p NB_PEERS
  end
end

module WLXP
  include WLRunner

  PEERS_ADDRESS = %w(
  localhost:12345
  localhost:12346
  localhost:12347
  )

  

  # Giving a program file generated from data_generators start the peer given in
  # the name of the file using the address found in the program file
  def create_wl_runner pg_file
    ip = port = ''
    pg_splitted = pg_file.split "_"
    peername = pg_splitted.last
    file = File.new "pg_file", "r"
    endloop = false
    while endloop and line = file.gets
      if(/^peer/.match line and line.includes? peername) # find line which contains peer current peer address
        peerline = line.split "="
        peerline.slice(-1) # remove last ;
        ip, port = peerline.slice ":"
      else
        raise WLError, "impossible to find the peername given in the end of the program \
filename: #{peername} in the list of peer specified in the program"
      end
    end
    WLRunner.create(peername, pg_file, port, {ip: ip, measure: true})
  end # def start_peer  
  
end # module WLXP

include WLXP
run! if __FILE__==$0
