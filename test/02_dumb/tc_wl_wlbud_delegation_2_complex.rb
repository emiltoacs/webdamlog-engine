$:.unshift File.dirname(__FILE__)
require_relative '../header_test'

class TcWlDelegation2Complex < Test::Unit::TestCase
  include MixinTcWlTest

  @@first_test=true
  NUMBER_OF_TEST_PG = 4
  TEST_FILENAME_VAR = "test_filename_"
  CLASS_PEER_NAME = "Test1complexdelegation"
  PREFIX_PORT_NUMBER = "1111"

  STR0 = <<EOF
peer p0=localhost:11110;
peer p1=localhost:11111;
peer p2=localhost:11112;
peer p3=localhost:11113;
collection ext persistent local@p0(atom1*);
collection ext per join_delegated@p0(atom1*);
fact local@p0(1);
fact local@p0(2);
fact local@p0(3);
fact local@p0(4);
rule join_delegated@p0($x):- local@p0($x),delegated@p1($x),delegated@p2($x),delegated@p3($x);
end
EOF

  STR1 = <<EOF
peer p0=localhost:11110;
peer p1=localhost:11111;
peer p2=localhost:11112;
peer p3=localhost:11113;
collection ext persistent delegated@p1(atom1*);
fact delegated@p1(2);
fact delegated@p1(3);
fact delegated@p1(4);
fact delegated@p1(5);
end
EOF

  STR2 = <<EOF
peer p0=localhost:11110;
peer p1=localhost:11111;
peer p2=localhost:11112;
peer p3=localhost:11113;
collection ext persistent delegated@p2(atom1*);
fact delegated@p2(3);
fact delegated@p2(4);
fact delegated@p2(5);
fact delegated@p2(6);
end
EOF

  STR3 = <<EOF
peer p0=localhost:11110;
peer p1=localhost:11111;
peer p2=localhost:11112;
peer p3=localhost:11113;
collection ext persistent delegated@p3(atom1*);
fact delegated@p3(4);
fact delegated@p3(5);
fact delegated@p3(6);
fact delegated@p3(7);
end
EOF

  def setup
    if @@first_test
      create_wlpeers_classes(NUMBER_OF_TEST_PG, CLASS_PEER_NAME)
      @@first_test=false
    end
    @wloptions = Struct.new :ip, :port, :wl_test
    (0..NUMBER_OF_TEST_PG-1).each do |i|
      eval("@#{TEST_FILENAME_VAR}#{i} = \"prog_#{create_name}_peer#{i}\"")
      eval("@tcoption#{i} = @wloptions.new \"localhost\",\"#{PREFIX_PORT_NUMBER}#{i}\",\"true\"")
    end
  end

  def teardown
    (0..NUMBER_OF_TEST_PG-1).each do |i|
      eval("File.delete @#{TEST_FILENAME_VAR}#{i} if File.exist? @#{TEST_FILENAME_VAR}#{i}")
    end
  end
  
  def test_1_complex_delegation
    
    p "===START of test_1===" if $test_verbose
    wl_peer = []
    (0..NUMBER_OF_TEST_PG-1).each do |i|
      wl_peer << eval("@@#{CLASS_PEER_NAME}#{i}.new(\'p#{i}\', STR#{i}, @#{TEST_FILENAME_VAR}#{i}, Hash[@tcoption#{i}.each_pair.to_a])")
    end
    p "===all wl_peer tick 1 in reverse order===" if $test_verbose
    p " such that p0 is sending its message after everyone has been initialized" if $test_verbose    
    wl_peer.reverse_each do |p|
      p " peer #{p.peername} start a tick" if $test_verbose
      p.tick
    end
    p "check table bootstrap content" if $test_verbose
    assert_equal [["1"],["2"],["3"],["4"]], wl_peer[0].local_at_p0.to_a.sort
    assert_equal [], wl_peer.first.join_delegated_at_p0.to_a.sort
    assert_equal [["2"],["3"],["4"],["5"]], wl_peer[1].delegated_at_p1.to_a.sort
    assert_equal [["3"],["4"],["5"],["6"]], wl_peer[2].delegated_at_p2.to_a.sort
    assert_equal [["4"],["5"],["6"],["7"]], wl_peer[3].delegated_at_p3.to_a.sort
    p "check message sent from p0 to p1" if $test_verbose
    assert_equal [
      {:dst=>"localhost:11111", :rel_name=>"deleg_from_p0_1_1_at_p1", :fact=>["1"]},
      {:dst=>"localhost:11111", :rel_name=>"deleg_from_p0_1_1_at_p1", :fact=>["2"]},
      {:dst=>"localhost:11111", :rel_name=>"deleg_from_p0_1_1_at_p1", :fact=>["3"]},
      {:dst=>"localhost:11111", :rel_name=>"deleg_from_p0_1_1_at_p1", :fact=>["4"]}],
      wl_peer[0].tables[:sbuffer].sort.map { |t| Hash[t.each_pair.to_a] },
      "content of sbuffer: facts sent from p0 to p1 looks incorrect"
    assert_equal 4, wl_peer[0].sbuffer.length
    assert_equal [["1"], ["2"], ["3"], ["4"]], wl_peer[0].sbuffer.to_a.sort.map{ |obj| obj.fact }, "p0 send its local relation content to p1"
    
    assert_equal 1, wl_peer[0].test_send_on_chan.length, "should have sent 1 packet"
    assert_equal [["localhost:11111",
        ["p0",
          "0",
          {:facts=>{"deleg_from_p0_1_1_at_p1"=>[["1"], ["2"], ["3"], ["4"]]},
            :rules=>
              ["rule join_delegated@p0($x):-deleg_from_p0_1_1@p1($x),delegated@p1($x),delegated@p2($x),delegated@p3($x);"],
            :declarations=>
              ["collection inter persistent deleg_from_p0_1_1@p1(deleg_from_p0_1_1_x_0*);"],
            :facts_to_delete=>{}}]]],
      wl_peer[0].test_send_on_chan.map { |p| (WLBud::WLPacket.deserialize_from_channel_sorted(p)).serialize_for_channel },
      "p0 must have sent a packet with new rule declaration and facts"
    p "check inbound queue at p1" if $test_verbose
    assert(wait_inbound(wl_peer[1]), "TIMEOUT it seems that #{wl_peer[1].peername} is not receiving any message")
    assert_equal 1, wl_peer[1].inbound.length, "one packet pending to be processed"
    packet = nil
    assert_nothing_raised { packet = WLBud::WLPacket.deserialize_from_channel_sorted(wl_peer[1].inbound[:chan].first) }
    assert_equal 3, packet.data.length, "packet value must have 3 significant fields"
    assert_equal 3, packet.data.length, "data in packet value must have three entries"    
    assert_equal 1, packet.data.facts.length, "should receive new insertions for one relations only"
    assert_equal ["localhost:11111",
      ["p0",
        "0",
        {:facts=>{"deleg_from_p0_1_1_at_p1"=>[["1"], ["2"], ["3"], ["4"]]},
          :rules=>
            ["rule join_delegated@p0($x):-deleg_from_p0_1_1@p1($x),delegated@p1($x),delegated@p2($x),delegated@p3($x);"],
          :declarations=>
            ["collection inter persistent deleg_from_p0_1_1@p1(deleg_from_p0_1_1_x_0*);"],
          :facts_to_delete=>{}}]],
      packet.serialize_for_channel


    p "===all wl_peer tick 2===" if $test_verbose
    p "p0 sent" if $test_verbose
    wl_peer[0].tick
    assert_equal [],
      wl_peer[0].test_send_on_chan.map { |p| (WLBud::WLPacket.deserialize_from_channel_sorted(p)).serialize_for_channel },
      "nothing since there is nothing new wince last tick"
    
    sleep 0.2 # wait for the second to be receive
    assert(wait_inbound(wl_peer[1]), "TIMEOUT it seems that #{wl_peer[1].peername} is not receiving any message")
    # #assert_equal 2, wl_peer[1].inbound[:chan].length, "two packets pending to
    # be processed"
    assert_equal [["localhost:11111",
        ["p0",
          "0",
          {"facts"=>{"deleg_from_p0_1_1_at_p1"=>[["1"], ["2"], ["3"], ["4"]]},
            "rules"=>
              ["rule join_delegated@p0($x):-deleg_from_p0_1_1@p1($x),delegated@p1($x),delegated@p2($x),delegated@p3($x);"],
            "declarations"=>
              ["collection inter persistent deleg_from_p0_1_1@p1(deleg_from_p0_1_1_x_0*);"],
            "facts_to_delete"=>{}}]]],
      wl_peer[1].inbound[:chan],
      "the first packet from p1 correspond to delegation rules and facts for \
this rules and there is no packet emitted by p1 at timestep 1"

    p "data at p1" if $test_verbose
    wl_peer[1].tick
    assert_equal [["1"], ["2"], ["3"], ["4"]], wl_peer[1].tables[:deleg_from_p0_1_1_at_p1].map { |t| t.values }, "lacks facts in delegated relation"
    assert_equal ["sbuffer <= ((deleg_from_p0_1_1_at_p1 * delegated_at_p1).combos(deleg_from_p0_1_1_at_p1.deleg_from_p0_1_1_x_0 => (delegated_at_p1.atom1)) do |atom0, atom1|\n  [\"localhost:11112\", \"deleg_from_p1_1_1_at_p2\", [atom0[0]]]\nend)"],
      wl_peer[1].t_rules.map{ |t| t.src },
      "there should be a rule to propagate the join between p0 and p1 to p2"
    assert_equal [["localhost:11112",
        ["p1",
          "1",
          {:facts=>{"deleg_from_p1_1_1_at_p2"=>[["2"], ["3"], ["4"]]},
            :rules=>
              ["rule join_delegated@p0($x):-deleg_from_p1_1_1@p2($x),delegated@p2($x),delegated@p3($x);"],
            :declarations=>
              ["collection inter persistent deleg_from_p1_1_1@p2(deleg_from_p1_1_1_x_0*);"],
            :facts_to_delete=>{}}]]],
      wl_peer[1].test_send_on_chan.map { |p| (WLBud::WLPacket.deserialize_from_channel_sorted(p)).serialize_for_channel },
      "p1 should have sent the list of facts, the new rule and the new declaration"

    assert(wait_inbound(wl_peer[2]), "TIMEOUT it seems that #{wl_peer[2].peername} is not receiving any message")
    assert_equal 1, wl_peer[2].inbound.length, "one packet pending to be processed"
    p "data at p2" if $test_verbose
    wl_peer[2].tick
    assert_equal [["localhost:11113",
        ["p2",
          "1",
          {:facts=>{"deleg_from_p2_1_1_at_p3"=>[["3"], ["4"]]},
            :rules=>
              ["rule join_delegated@p0($x):-deleg_from_p2_1_1@p3($x),delegated@p3($x);"],
            :declarations=>
              ["collection inter persistent deleg_from_p2_1_1@p3(deleg_from_p2_1_1_x_0*);"],
            :facts_to_delete=>{}}]]],
      wl_peer[2].test_send_on_chan.map { |p| (WLBud::WLPacket.deserialize_from_channel_sorted(p)).serialize_for_channel },
      "p2 should have sent the list of facts, the new rule and the new declaration"

    assert(wait_inbound(wl_peer[3]), "TIMEOUT it seems that #{wl_peer[2].peername} is not receiving any message")
    assert_equal 1, wl_peer[3].inbound.length, "one packet pending to be processed"
    p "data at p3" if $test_verbose
    wl_peer[3].tick
    assert_equal [["localhost:11110",
        ["p3",
          "1",
          {:rules=>[],
            :facts=>{"join_delegated_at_p0"=>[["4"]]},
            :declarations=>[],
            :facts_to_delete=>{}}]]],
      wl_peer[3].test_send_on_chan.map { |p| (WLBud::WLPacket.deserialize_from_channel_sorted(p)).serialize_for_channel },
      "p3 should have sent the list of facts to p0"

    assert(wait_inbound(wl_peer[0]), "TIMEOUT it seems that #{wl_peer[2].peername} is not receiving any message")
    assert_equal 1, wl_peer[0].inbound.length, "one packet pending to be processed"
    p "data at p0" if $test_verbose
    assert wl_peer[0].join_delegated_at_p0.empty?
    wl_peer[0].tick
    assert_equal 1, wl_peer[0].test_received_on_chan.length, "p0 should have received one packet"
    packet_data = wl_peer[0].test_received_on_chan.first
    assert packet_data.rules.empty?
    assert packet_data.declarations.empty?
    assert_equal( {"join_delegated_at_p0" => [["4"]]}, packet_data.facts )
    assert_equal 1, wl_peer[0].join_delegated_at_p0.length
  ensure
    wl_peer.each { |item| assert item.clear_rule_dir }
    if EventMachine::reactor_running?
      wl_peer[0..-2].each { |item| item.stop } # for all except the last
      wl_peer.last.stop(true) # for the last I also stop EM to be clean
    end
  end
end

# Test every king of delegations fully non-local, body non-local or partially
# body local
class TcWlDelegation2FullynonLocal < Test::Unit::TestCase
  include MixinTcWlTest

  @@first_test=true
  NUMBER_OF_TEST_PG = 3
  TEST_FILENAME_VAR = "test_every_kind_of_delegation_"
  CLASS_PEER_NAME = "PeerDeleg2FullynonLocal"
  PREFIX_PORT_NUMBER = "1111"

  STR0 = <<EOF
peer p0=localhost:11110;
peer p1=localhost:11111;
peer p2=localhost:11112;
collection ext persistent local@p0(atom1*);
collection ext persistent copy1@p0(atom1*);
collection ext persistent copy2@p0(atom1*);
collection ext per join_delegated@p0(atom1*);
fact local@p0(p0_1);
fact local@p0(p0_2);
fact local@p0("jointuple");
rule join_delegated@p0($x):- local@p0($x),local@p1($x),local@p2($x); # test delegation
rule extcopylocalatp1@p2($X):-local@p1($X); # test full non-local rule
EOF

  STR1 = <<EOF
peer p0=localhost:11110;
peer p1=localhost:11111;
peer p2=localhost:11112;
collection ext persistent local@p1(atom1*);
collection ext persistent copylocalatp2@p1(atom1*);
fact local@p1("p1_2");
fact local@p1("p1_3");
fact local@p1("jointuple");
rule copylocalatp2@p1($X):-local@p2($X); # test body non-local delegation
EOF

  STR2 = <<EOF
peer p0=localhost:11110;
peer p1=localhost:11111;
peer p2=localhost:11112;
collection ext persistent local@p2(atom1*);
collection ext per extcopylocalatp1@p2(atom1*);
fact local@p2("p2_3");
fact local@p2("p2_4");
fact local@p2("jointuple");
EOF

  def setup
    if @@first_test
      create_wlpeers_classes(NUMBER_OF_TEST_PG, CLASS_PEER_NAME)
      @@first_test=false
    end
    @wloptions = Struct.new :ip, :port, :wl_test
    (0..NUMBER_OF_TEST_PG-1).each do |i|
      eval("@#{TEST_FILENAME_VAR}#{i} = \"prog_#{create_name}_peer#{i}\"")
      eval("@tcoption#{i} = @wloptions.new \"localhost\",\"#{PREFIX_PORT_NUMBER}#{i}\",\"true\"")
    end
  end

  def teardown
    (0..NUMBER_OF_TEST_PG-1).each do |i|
      eval("File.delete @#{TEST_FILENAME_VAR}#{i} if File.exist? @#{TEST_FILENAME_VAR}#{i}")
    end
  end

  
  def test_every_kind_of_delegation
    # declare three peers with previous program
    wl_peer = []
    (0..NUMBER_OF_TEST_PG-1).each do |i|
      wl_peer << eval("@@#{CLASS_PEER_NAME}#{i}.new(\'p#{i}\', STR#{i}, @#{TEST_FILENAME_VAR}#{i}, Hash[@tcoption#{i}.each_pair.to_a])")
    end
    

    # start p2 with nothing to do
    wl_peer[2].tick
    # check that there is no rules
    assert_equal([],
      wl_peer[2].wl_program.rule_mapping.values.map{ |ar| ar.first.show_wdl_format})
    # check that all collection are empty
    assert_equal([{:chan=>[]},
        {:extcopylocalatp1_at_p2=>[]},
        {:local_at_p2=>[{:atom1=>"p2_3"}, {:atom1=>"p2_4"}, {:atom1=>"jointuple"}]},
        {:sbuffer=>[]}],
      wl_peer[2].app_tables.map { |item| item.tabname }.sort.map { |at|
        tab = wl_peer[2].tables[at].map { |t|
          h = Hash[t.each_pair.to_a]
          h.delete(:wdl_rule_id)
          h.delete(:port)
          h
        }
        Hash[at, tab]
      }
    )
    

    # start p1 which send a delegation to p2
    wl_peer[1].tick
    # check that there is no local rules
    assert_equal([
        "rule copylocalatp2@p1($X) :- local@p2($X);",
        "rule copylocalatp2@p1($X) :- local@p2($X);"],
      wl_peer[1].wl_program.rule_mapping.values.map do |ar|
        if ar.first.is_a? WLBud::WLRule
          ar.first.show_wdl_format
        else
          ar.first
        end      
      end)
    # check that all collection are empty except local@p1
    assert_equal([{:chan=>[]},
        {:copylocalatp2_at_p1=>[]},
        {:local_at_p1=>[{:atom1=>"p1_2"}, {:atom1=>"p1_3"}, {:atom1=>"jointuple"}]},
        {:sbuffer=>[]}],
      wl_peer[1].app_tables.map { |item| item.tabname }.sort.map { |at|
        tab = wl_peer[1].tables[at].map { |t|
          h = Hash[t.each_pair.to_a]
          h.delete(:wdl_rule_id)
          h.delete(:port)
          h
        }
        Hash[at, tab]
      }
    )
    sleep 0.1

    # fire p2 to install the delegation
    wl_peer[2].tick
    # check that there is one new rule installed
    assert_equal(["WLRULE: rule copylocalatp2@p1($X) :- local@p2($X);"],
      wl_peer[2].wl_program.rule_mapping.values.map do |ar|
        if ar.first.is_a? WLBud::WLRule
          "WLRULE: " + ar.first.show_wdl_format
        else
          "String: " + ar.first
        end
      end)
    # check that the new rule makes p2 send facts
    assert_equal([{:chan=>[]},
        {:extcopylocalatp1_at_p2=>[]},
        {:local_at_p2=>[{:atom1=>"p2_3"}, {:atom1=>"p2_4"}, {:atom1=>"jointuple"}]},
        {:sbuffer=>
            [{:dst=>"localhost:11111",
              :rel_name=>"copylocalatp2_at_p1",
              :fact=>["p2_3"]},
            {:dst=>"localhost:11111",
              :rel_name=>"copylocalatp2_at_p1",
              :fact=>["p2_4"]},
            {:dst=>"localhost:11111",
              :rel_name=>"copylocalatp2_at_p1",
              :fact=>["jointuple"]}]}],
      wl_peer[2].app_tables.map { |item| item.tabname }.sort.map { |at|
        tab = wl_peer[2].tables[at].map { |t|
          h = Hash[t.each_pair.to_a]
          h.delete(:wdl_rule_id)
          h.delete(:port)
          h
        }
        Hash[at, tab]
      }
    )
    

    # fire p1 to check that facts from the delegation to p2 has been produced
    # and sent to p1
    wl_peer[1].tick
    wl_peer[1].tick
    # there is no new rules only the remember that we made a delegation
    assert_equal(["WLRULE: rule copylocalatp2@p1($X) :- local@p2($X);",
        "String: rule copylocalatp2@p1($X) :- local@p2($X);"],
      wl_peer[1].wl_program.rule_mapping.values.map do |ar|
        if ar.first.is_a? WLBud::WLRule
          "WLRULE: " + ar.first.show_wdl_format
        else
          "String: " + ar.first
        end
      end)
    # but there are new facts thanks to the result of evaluating the delegation
    assert_equal([{:chan=>[]},
        {:copylocalatp2_at_p1=>
            [{:atom1=>"p2_3"}, {:atom1=>"p2_4"}, {:atom1=>"jointuple"}]},
        {:local_at_p1=>[{:atom1=>"p1_2"}, {:atom1=>"p1_3"}, {:atom1=>"jointuple"}]},
        {:sbuffer=>[]}],
      wl_peer[1].app_tables.map { |item| item.tabname }.sort.map { |at|
        tab = wl_peer[1].tables[at].map { |t|
          h = Hash[t.each_pair.to_a]
          h.delete(:wdl_rule_id)
          h.delete(:port)
          h
        }
        Hash[at, tab]
      })

    # fire p0 to send the complex 2 hops delegation
    wl_peer[0].tick
    assert_equal(["WLRULE: rule join_delegated@p0($x) :- local@p0($x), local@p1($x), local@p2($x);",
        "WLRULE: rule extcopylocalatp1@p2($X) :- local@p1($X);",
        "WLRULE: rule deleg_from_p0_1_1@p1($x) :- local@p0($x);",
        "String: rule join_delegated@p0($x):-deleg_from_p0_1_1@p1($x),local@p1($x),local@p2($x);",
        "String: rule extcopylocalatp1@p2($X) :- local@p1($X);"],
      wl_peer[0].wl_program.rule_mapping.values.map do |ar|
        if ar.first.is_a? WLBud::WLRule
          "WLRULE: " + ar.first.show_wdl_format
        else
          "String: " + ar.first
        end
      end)

    # fire p1 to process the delegation
    assert(wait_inbound(wl_peer[1]), "You have lost message")
    wl_peer[1].tick
    assert_equal(["WLRULE: rule copylocalatp2@p1($X) :- local@p2($X);",
        "String: rule copylocalatp2@p1($X) :- local@p2($X);",
        "WLRULE: rule join_delegated@p0($x) :- deleg_from_p0_1_1@p1($x), local@p1($x), local@p2($x);",
        "WLRULE: rule deleg_from_p1_2_1@p2($x) :- deleg_from_p0_1_1@p1($x), local@p1($x);",
        "String: rule join_delegated@p0($x):-deleg_from_p1_2_1@p2($x),local@p2($x);",
        "WLRULE: rule extcopylocalatp1@p2($X) :- local@p1($X);"],
      wl_peer[1].wl_program.rule_mapping.values.map do |ar|
        if ar.first.is_a? WLBud::WLRule
          "WLRULE: " + ar.first.show_wdl_format
        else
          "String: " + ar.first
        end
      end)
    assert_equal([{:deleg_from_p0_1_1_x_0=>"p0_1"},
        {:deleg_from_p0_1_1_x_0=>"p0_2"},
        {:deleg_from_p0_1_1_x_0=>"jointuple"}],
      wl_peer[1].tables[:deleg_from_p0_1_1_at_p1].map do |t|
        h = Hash[t.each_pair.to_a]
        h
      end)
    assert_equal([{:dst=>"localhost:11112",
          :rel_name=>"deleg_from_p1_2_1_at_p2",
          :fact=>["jointuple"]},
        {:dst=>"localhost:11112",
          :rel_name=>"extcopylocalatp1_at_p2",
          :fact=>["jointuple"]},
        {:dst=>"localhost:11112",
          :rel_name=>"extcopylocalatp1_at_p2",
          :fact=>["p1_2"]},
        {:dst=>"localhost:11112",
          :rel_name=>"extcopylocalatp1_at_p2",
          :fact=>["p1_3"]}],
      wl_peer[1].tables[:sbuffer].sort.map do |t|
        h = Hash[t.each_pair.to_a]
        h
      end)

    # fire p2 to process the following of the delegation
    assert(wait_inbound(wl_peer[2]), "You have lost message")
    wl_peer[2].tick
    assert_equal(["WLRULE: rule copylocalatp2@p1($X) :- local@p2($X);",
        "WLRULE: rule join_delegated@p0($x) :- deleg_from_p1_2_1@p2($x), local@p2($x);"],
      wl_peer[2].wl_program.rule_mapping.values.map do |ar|
        if ar.first.is_a? WLBud::WLRule
          "WLRULE: " + ar.first.show_wdl_format
        else
          "String: " + ar.first
        end
      end)
    assert_equal([{:deleg_from_p1_2_1_x_0=>"jointuple"}],
      wl_peer[2].tables[:deleg_from_p1_2_1_at_p2].map do |t|
        h = Hash[t.each_pair.to_a]
        h
      end)

    # check the status of p0
    assert(wait_inbound(wl_peer[0]), "You have lost message")
    wl_peer[0].tick
    # there is no new rules only the remember that we made a delegation
    assert_equal(["WLRULE: rule join_delegated@p0($x) :- local@p0($x), local@p1($x), local@p2($x);",
        "WLRULE: rule extcopylocalatp1@p2($X) :- local@p1($X);",
        "WLRULE: rule deleg_from_p0_1_1@p1($x) :- local@p0($x);",
        "String: rule join_delegated@p0($x):-deleg_from_p0_1_1@p1($x),local@p1($x),local@p2($x);",
        "String: rule extcopylocalatp1@p2($X) :- local@p1($X);"],
      wl_peer[0].wl_program.rule_mapping.values.map do |ar|
        if ar.first.is_a? WLBud::WLRule
          "WLRULE: " + ar.first.show_wdl_format
        else
          "String: " + ar.first
        end
      end)
    # but there are new facts thanks to the result of evaluating the delegation
    assert_equal([{:chan=>[]},
        {:copy1_at_p0=>[]},
        {:copy2_at_p0=>[]},
        {:deleg_from_p0_1_1_at_p1=>[]},
        {:join_delegated_at_p0=>[{:atom1=>"jointuple"}]},
        {:local_at_p0=>[{:atom1=>"p0_1"}, {:atom1=>"p0_2"}, {:atom1=>"jointuple"}]},
        {:sbuffer=>
            [{:dst=>"localhost:11111",
              :rel_name=>"deleg_from_p0_1_1_at_p1",
              :fact=>["p0_1"]},
            {:dst=>"localhost:11111",
              :rel_name=>"deleg_from_p0_1_1_at_p1",
              :fact=>["p0_2"]},
            {:dst=>"localhost:11111",
              :rel_name=>"deleg_from_p0_1_1_at_p1",
              :fact=>["jointuple"]}]}],
      wl_peer[0].app_tables.map { |item| item.tabname }.sort.map do |at|
        tab = wl_peer[0].tables[at].map do |t|
          h = Hash[t.each_pair.to_a]
          h.delete(:wdl_rule_id)
          h.delete(:port)
          h
        end
        Hash[at, tab]
      end)

    # check that the fully non-local rule from p0: rule extcopy@p2($X) :-
    # local@p1($X); has been installed on p1
    assert_equal(["rule copylocalatp2@p1($X) :- local@p2($X);",
        "rule copylocalatp2@p1($X) :- local@p2($X);",
        "rule join_delegated@p0($x) :- deleg_from_p0_1_1@p1($x), local@p1($x), local@p2($x);",
        "rule deleg_from_p1_2_1@p2($x) :- deleg_from_p0_1_1@p1($x), local@p1($x);",
        "rule join_delegated@p0($x):-deleg_from_p1_2_1@p2($x),local@p2($x);",
        "rule extcopylocalatp1@p2($X) :- local@p1($X);"],
      wl_peer[1].wl_program.rule_mapping.values.map do |ar|
        if ar.first.is_a? WLBud::WLRule
          ar.first.show_wdl_format
        else
          ar.first
        end
      end)
    
    # check facts on p2
    assert_equal([{:chan=>[]},
        {:deleg_from_p1_2_1_at_p2=>[{:deleg_from_p1_2_1_x_0=>"jointuple"}]},
        {:extcopylocalatp1_at_p2=>
            [{:atom1=>"p1_2"}, {:atom1=>"p1_3"}, {:atom1=>"jointuple"}]},
        {:local_at_p2=>[{:atom1=>"p2_3"}, {:atom1=>"p2_4"}, {:atom1=>"jointuple"}]},
        {:sbuffer=>
            [{:dst=>"localhost:11111",
              :rel_name=>"copylocalatp2_at_p1",
              :fact=>["p2_3"]},
            {:dst=>"localhost:11111",
              :rel_name=>"copylocalatp2_at_p1",
              :fact=>["p2_4"]},
            {:dst=>"localhost:11111",
              :rel_name=>"copylocalatp2_at_p1",
              :fact=>["jointuple"]},
            {:dst=>"localhost:11110",
              :rel_name=>"join_delegated_at_p0",
              :fact=>["jointuple"]}]}],
      wl_peer[2].app_tables.map { |item| item.tabname }.sort.map { |at|
        tab = wl_peer[2].tables[at].map { |t|
          h = Hash[t.each_pair.to_a]
          h.delete(:wdl_rule_id)
          h.delete(:port)
          h
        }
        Hash[at, tab]
      })
  ensure
    wl_peer.each { |item| assert item.clear_rule_dir }
    if EventMachine::reactor_running?
      wl_peer[0..-2].each { |item| item.stop } # for all except the last
      wl_peer.last.stop(true) # for the last I also stop EM to be clean
    end
  end
  
end
