# ####License####
#  File name tc_bud_send_packet.rb
#  Copyright © by INRIA
# 
#  Contributors : Webdam Team <webdam.inria.fr>
#       Emilien Antoine <emilien[dot]antoine[@]inria[dot]fr>
# 
#   WebdamLog - Aug 8, 2012
# 
#   Encoding - UTF-8
# ####License####
$:.unshift File.dirname(__FILE__)
require 'header_test'

# Test designed to check the behavior of rules with delegations.
#
class TcWlBudSendPacket < Test::Unit::TestCase  
  include MixinTcWlTest

  @@first_test=true
  NUMBER_OF_TEST_PG = 2
  TEST_FILENAME_VAR = "test_filename_"
  CLASS_PEER_NAME = "Peer"
  PREFIX_PORT_NUMBER = "1111"

  def setup
    if @@first_test
      create_wlpeers_classes(NUMBER_OF_TEST_PG, CLASS_PEER_NAME)
      @@first_test=false
    end
    @wloptions = Struct.new :ip, :port, :wl_test
    (0..NUMBER_OF_TEST_PG-1).each do |i|
      eval("@#{TEST_FILENAME_VAR}#{i} = \"prog_#{create_name}_#{i}\"")
      eval("@tcoption#{i} = @wloptions.new \"localhost\",
 \"#{PREFIX_PORT_NUMBER}#{i}\",\"true\"")
    end
  end

  def teardown
    #    self.class.constants.each{ |item| p "#{item} : #{eval(item)}"if item=~/FILENAME/ }
    (0..NUMBER_OF_TEST_PG-1).each do |i|
      #      p Dir.entries((File.dirname("TEST_FILENAME_VAR#{i}"))).inspect+" in dir"
      #      p File.exist?(eval("TEST_FILENAME_VAR#{i}")).to_s+" exists?"
      #      p File.expand_path(File.dirname("TEST_FILENAME_VAR#{i}")).to_s+" dirname"
      eval("File.delete @#{TEST_FILENAME_VAR}#{i} if File.exist? @#{TEST_FILENAME_VAR}#{i}")
      #      p File.exist?(eval("TEST_FILENAME_VAR#{i}")).to_s+" exists?"
    end
  end

    STR0 = <<EOF
peer p0=localhost:11110;
peer p1=localhost:11111;
collection ext persistent local@p0(at1*,at2*);
collection ext persistent local2@p0(at1*,at2*);
collection int join@p0(at1*);
collection int join@p1(at1*,at2*);
fact local@p0(1,21);
fact local@p0(2,22);
fact local@p0(3,23);
fact local@p0(4,24);
fact local2@p0(3,23);
fact local2@p0(4,24);
fact local2@p0(5,25);
fact local2@p0(6,26);
fact local2@p0(7,27);
rule join@p0($x):- local@p0($x,_),local2@p0($x,_);
rule join@p1($x,$y):- local@p0($x,$y),local2@p0($x,$y);
end
EOF
  STR1 = <<EOF
peer p0=localhost:11110;
peer p1=localhost:11111;
collection ext persistent join@p1(at1*,at2*);
end
EOF

  # Test the communication between peers.
  #
  # Test a join in local and delegated manner into a extensional persistent
  # relation.
  #
  def test_1_join_extensional
    if $test_verbose
      $BUD_DEBUG = true
    end
    
    wl_peer = []
    (0..1).each do |i|
      assert_nothing_raised do
        wl_peer << eval("@@Peer#{i}.new(\'p#{i}\', STR#{i}, @#{TEST_FILENAME_VAR}#{i}, Hash[@tcoption#{i}.each_pair.to_a])")
      end
    end
    
    # p "===all wl_peer tick 1 in reverse order==="
    wl_peer.reverse_each do |p|
      p.tick
    end
    
    # p "check content of p0 the peer which send"
    assert_equal 4, wl_peer[0].local_at_p0.length
    assert_equal [["1","21"], ["2","22"], ["3","23"], ["4","24"]], 
      wl_peer[0].local_at_p0.to_a.sort
    assert_equal 5, wl_peer[0].local2_at_p0.length
    assert_equal [["3","23"], ["4","24"], ["5","25"], ["6","26"], ["7","27"]], 
      wl_peer[0].local2_at_p0.to_a.sort
    assert_equal 2, wl_peer[0].join_at_p0.length
    assert_equal [["3"], ["4"]], wl_peer[0].join_at_p0.to_a.sort
    assert_equal 2, wl_peer[0].sbuffer.length
    assert_equal [["3","23"], ["4","24"]], 
      wl_peer[0].sbuffer.map { |m| m.fact }.to_a.sort    
    # p "test method deserialize_from_channel and check content written on chan"
    assert_equal 1, wl_peer[0].test_send_on_chan.length, "should send 1 packet"
    packet = nil
    assert_nothing_raised do 
      packet = WLBud::WLPacket.deserialize_from_channel(wl_peer[0].test_send_on_chan.first)
    end
    assert_equal wl_peer[0].wl_program.wlpeers['p1'], packet.dest,
      "one new packet for peer p1"
    assert_not_nil packet.data.facts,
      "there should be new fact to insert for p1"
    assert_equal [["3", "23"], ["4", "24"]], packet.data.facts.first[1].sort, 
      "expected content of list of facts to insert"
    # p "check message received at p1 in inbound"
    # p "next tick will put inbound message into chan collection"
    assert(EventMachine::reactor_running?, "reactor should be running")
    assert(!EventMachine::reactor_thread?, "reactor should not be the test thread")
    cpt=0
    while wl_peer[1].inbound.empty?
      sleep 0.2
      cpt += 1
      if cpt>7
        assert(false, "it seems that peer1 is not receiving the message from peer 0")
      end
    end
    #p "wait in send_packet to let EventMachine take the priority"
    assert_equal 1, wl_peer[1].inbound.length,
      "only one relation pending queue is non-empty"
    assert_equal 1, wl_peer[1].inbound[:chan].length,
      "only one packet for :chan"
    assert_nothing_raised do 
      packet = WLBud::WLPacket.deserialize_from_channel(wl_peer[1].inbound[:chan].first)     
    end
    assert_equal wl_peer[1].wl_program.wlpeers['me'], packet.dest, 
      "one new packet for local peer named p1"
    assert_equal 1, packet.data.length, 
      "data in packet value must have only new facts updates"
    assert_equal 1, packet.data.facts.length, 
      "should receive new insertions for one relations only"
    assert_equal 2, packet.data.facts.first.length,
      "should receive two facts to insert"
    assert_equal [["3", "23"], ["4", "24"]], packet.data.facts.first[1].sort,
      "wrong content received"

    #p "===all wl_peer tick 2==="
    #p "check that p1 correctly update its state"    
    wl_peer.reverse_each do |p|
      p.tick
    end
    assert_equal 2, wl_peer[1].join_at_p1.length
    assert_equal [["3", "23"], ["4", "24"]], wl_peer[1].join_at_p1.to_a.sort

    #p "===all wl_peer tick 3==="
    #p "check that all peers correctly update their state in subsequent ticks"
    wl_peer.each do |p|
      p.tick
    end
    assert_equal 2, wl_peer[0].join_at_p0.length
    assert_equal [["3"], ["4"]], wl_peer[0].join_at_p0.to_a.sort
    assert_equal 2, wl_peer[1].join_at_p1.length
    assert_equal [["3", "23"], ["4", "24"]], wl_peer[1].join_at_p1.to_a.sort

    #p "===all wl_peer tick 4==="
    #p "check that all peers correctly update their state in subsequent ticks"
    wl_peer.each do |p|
      p.tick
    end
    assert_equal 2, wl_peer[0].join_at_p0.length
    assert_equal [["3"], ["4"]], wl_peer[0].join_at_p0.to_a.sort
    assert_equal 2, wl_peer[1].join_at_p1.length
    assert_equal [["3", "23"], ["4", "24"]], wl_peer[1].join_at_p1.to_a.sort
    
  ensure
    wl_peer.each { |item| assert item.clear_rule_dir }
    if EventMachine::reactor_running?
      wl_peer[0..-2].each { |item| item.stop } # for all except the last
      wl_peer.last.stop(true) # for the last I also stop EM to be clean
    end
  end
end
