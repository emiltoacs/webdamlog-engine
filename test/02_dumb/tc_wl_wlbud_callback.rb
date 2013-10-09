# ####License####
#  File name tc_wl_callback.rb
#  Copyright © by INRIA
# 
#  Contributors : Webdam Team <webdam.inria.fr>
#       Emilien Antoine <emilien[dot]antoine[@]inria[dot]fr>
# 
#   WebdamLog - Jul 8, 2012
# 
#   Encoding - UTF-8
# ####License####
$:.unshift File.dirname(__FILE__)
require_relative '../header_test'

class TcWlCallback < Test::Unit::TestCase

  NUMBER_OF_TEST_PG = 2
  PREFIX_PORT_NUMBER = "1111"  

  def setup
    wloptions = Struct.new :ip, :port, :wl_test
    (0..NUMBER_OF_TEST_PG-1).each do |i|
      eval("TEST_FILENAME#{i} = \"prog#{i}\"")
      eval("WLOPTIONS#{i} = wloptions.new \"localhost\",
 \"#{PREFIX_PORT_NUMBER}#{i}\",\"true\"")
    end
  end

  def teardown
    (0..NUMBER_OF_TEST_PG-1).each do |i|
      eval("File.delete TEST_FILENAME#{i} if File.exist? TEST_FILENAME#{i}")
    end
  end

  class PeerCallback < WLBud::WL
    STR0 = <<EOF
peer p0=localhost:11111;
peer p1=localhost:11112;
collection ext persistent local@p0(atom1*);
collection int joindelegated@p0(atom1*);
fact local@p0(1);
fact local@p0(2);
fact local@p0(3);
fact local@p0(4);
rule joindelegated@p0($x):- local@p0($x),delegated@p1($x);
end
EOF
    def initialize(peername, options={})
      File.open(TEST_FILENAME1,"w"){ |file| file.write STR0}
      super(peername, TEST_FILENAME1, options)
    end
  end

  # Test the block insertion mechanism. 
  #
  def test_callback_invoke
    wl_peer_1 = nil
    assert_nothing_raised {wl_peer_1 = PeerCallback.new('p0', Hash[WLOPTIONS1.each_pair.to_a])}
    get_public = {}
    get_private = []
    block = lambda do | wlbudinstance, *options |
      get_public = wlbudinstance.wl_callback
      get_private = wlbudinstance.instance_variable_get(:@declarations)
    end
    cb_id = wl_peer_1.register_wl_callback(:callback_step_received_on_chan, &block)
    wl_peer_1.tick
    assert(get_public.length > 0, "unable to retrieve the public value")
    assert(get_private.length > 0, "unable to retrieve the private value")
    wl_peer_1.unregister_wl_callback(cb_id)    
  ensure
    unless wl_peer_1.nil?
      wl_peer_1.clear_rule_dir
      if EventMachine::reactor_running?
        wl_peer_1.stop(true)
      end
    end
  end
end
