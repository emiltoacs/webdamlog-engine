# ####License####
#  File name tc_wl_delegation_2_complex.rb
#  Copyright © by INRIA
#
#  Contributors : Webdam Team <webdam.inria.fr>
#       Emilien Antoine <emilien[dot]antoine[@]inria[dot]fr>
#
#   WebdamLog - Aug 9, 2012
#
#   Encoding - UTF-8
# ####License####
$:.unshift File.dirname(__FILE__)
require 'header_test'

class TcWlDelegation2Complex < Test::Unit::TestCase
  include MixinTcWlTest

  @@first_test=true
  NUMBER_OF_TEST_PG = 4
  TEST_FILENAME_VAR = "test_filename_"
  CLASS_PEER_NAME = "PeerDeleg2Complex"
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

  # PENDING intensional not supported in non-local check with join collection
  # int join_delegated@p0(atom1*);
  #
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
    assert_equal [["1"],["2"],["3"],["4"]], wl_peer.first.local_at_p0.to_a.sort
    assert_equal [], wl_peer.first.join_delegated_at_p0.to_a.sort
    assert_equal [["2"],["3"],["4"],["5"]], wl_peer[1].delegated_at_p1.to_a.sort
    assert_equal [["3"],["4"],["5"],["6"]], wl_peer[2].delegated_at_p2.to_a.sort
    assert_equal [["4"],["5"],["6"],["7"]], wl_peer[3].delegated_at_p3.to_a.sort
    p "check message sent from p0 to p1" if $test_verbose
    assert_equal 4, wl_peer[0].sbuffer.length
    assert_equal [["1"], ["2"], ["3"], ["4"]], wl_peer[0].sbuffer.to_a.sort.map{ |obj| obj.fact }, "p0 send its local relation content to p1"
    assert_equal 1, wl_peer[0].rules_to_delegate.length
    assert_equal 1, wl_peer[0].relation_to_declare.length
    assert_equal 1, wl_peer[0].relation_to_declare.values.length    
    new_declaration = wl_peer[0].relation_to_declare.values.first.to_s
    /(deleg.*)\(/ =~ new_declaration
    new_rel_at_p1 = Regexp.last_match(1).gsub('@', '_at_')
    assert_kind_of Bud::BudScratch, wl_peer[0].tables[new_rel_at_p1.to_sym], "check the type of the newly created relation Table or Scratch"
    assert_equal 1, wl_peer[0].test_send_on_chan.length, "should have sent 1 packet"
    assert_equal [["localhost:11111",
        ["p0", "0",
          {"rules"=>
              ["rule join_delegated@p0($x):-deleg_from_p0_1_1@p1($x),delegated@p1($x),delegated@p2($x),delegated@p3($x);"],
            "facts"=>
              {"deleg_from_p0_1_1_at_p1"=>[["1"], ["2"], ["3"], ["4"]]},
            "declarations"=>
              ["collection inter persistent deleg_from_p0_1_1@p1(deleg_from_p0_1_1_x_0*);"]
          }]]],
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
        {"facts"=>{"deleg_from_p0_1_1_at_p1"=>[["1"], ["2"], ["3"], ["4"]]},
          "rules"=>
            ["rule join_delegated@p0($x):-deleg_from_p0_1_1@p1($x),delegated@p1($x),delegated@p2($x),delegated@p3($x);"],
          "declarations"=>
            ["collection inter persistent deleg_from_p0_1_1@p1(deleg_from_p0_1_1_x_0*);"]}]],
      packet.serialize_for_channel

    p "===all wl_peer tick 2===" if $test_verbose
    #    wl_peer.reverse_each do |p|
    #      p.tick
    #      sleep 1
    #    end
    p "p0 sent" if $test_verbose
    wl_peer[0].tick
    assert_equal [["localhost:11111",
        ["p0", "1", {"rules"=>[],
            "facts"=>{"deleg_from_p0_1_1_at_p1"=>[["1"], ["2"], ["3"], ["4"]]},
            "declarations"=>[]}]]],
      wl_peer[0].test_send_on_chan.map { |p| (WLBud::WLPacket.deserialize_from_channel_sorted(p)).serialize_for_channel },
      "p0 should have sent again the list of facts but not the declaratiosn or rules"

    assert(wait_inbound(wl_peer[1]), "TIMEOUT it seems that #{wl_peer[1].peername} is not receiving any message")
    assert_equal 2, wl_peer[1].inbound[:chan].first.length, "two packets pending to be processed"
    p "data at p1" if $test_verbose
    wl_peer[1].tick
    assert_equal [["localhost:11112",
        ["p1",
          "1",
          {"facts"=>{"deleg_from_p1_1_1_at_p2"=>[["2"], ["3"], ["4"]]},
            "rules"=>
              ["rule join_delegated@p0($x):-deleg_from_p1_1_1@p2($x),delegated@p2($x),delegated@p3($x);"],
            "declarations"=>
              ["collection inter persistent deleg_from_p1_1_1@p2(deleg_from_p1_1_1_x_0*);"]}]]],
      wl_peer[1].test_send_on_chan.map { |p| (WLBud::WLPacket.deserialize_from_channel_sorted(p)).serialize_for_channel },
      "p1 should have sent the list of facts, the new rule and the new declaration"

    assert(wait_inbound(wl_peer[2]), "TIMEOUT it seems that #{wl_peer[2].peername} is not receiving any message")
    assert_equal 1, wl_peer[2].inbound.length, "one packet pending to be processed"
    p "data at p2" if $test_verbose
    wl_peer[2].tick
    assert_equal [["localhost:11113",
        ["p2",
          "1",
          {"facts"=>{"deleg_from_p2_1_1_at_p3"=>[["3"], ["4"]]},
            "rules"=>
              ["rule join_delegated@p0($x):-deleg_from_p2_1_1@p3($x),delegated@p3($x);"],
            "declarations"=>
              ["collection inter persistent deleg_from_p2_1_1@p3(deleg_from_p2_1_1_x_0*);"]}]]],
      wl_peer[2].test_send_on_chan.map { |p| (WLBud::WLPacket.deserialize_from_channel_sorted(p)).serialize_for_channel },
      "p2 should have sent the list of facts, the new rule and the new declaration"

    assert(wait_inbound(wl_peer[3]), "TIMEOUT it seems that #{wl_peer[2].peername} is not receiving any message")
    assert_equal 1, wl_peer[3].inbound.length, "one packet pending to be processed"
    p "data at p3" if $test_verbose
    wl_peer[3].tick
    assert_equal [["localhost:11110",
        ["p3",
          "1",
          {"rules"=>[],
            "facts"=>{"join_delegated_at_p0"=>[["4"]]},
            "declarations"=>[]}]]],
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
fact local@p0(1);
fact local@p0(2);
fact local@p0(3);
fact local@p0(4);
fact local@p0("jointuple");
rule join_delegated@p0($x):- local@p0($x),local@p1($x),local@p2($x); # test delegation
rule copy1@p0($X):-local@p1($X); # test full non-local body delegation
rule copy2@p0($X):-local@p2($X);
rule extcopy@p2($X):-local@p1($X); # test full non-local rule
EOF

  STR1 = <<EOF
peer p0=localhost:11110;
peer p1=localhost:11111;
peer p2=localhost:11112;
collection ext persistent local@p1(atom1*);
collection ext persistent copy2@p1(atom1*);
fact local@p1("p1_2");
fact local@p1("p1_3");
fact local@p1("p1_4");
fact local@p1("p1_5");
fact local@p1("jointuple");
rule copy2@p1($X):-local@p2($X);
EOF

  STR2 = <<EOF
peer p0=localhost:11110;
peer p1=localhost:11111;
peer p2=localhost:11112;
collection ext persistent local@p2(atom1*);
collection ext per extcopy@p2(atom1*);
fact local@p2("p2_3");
fact local@p2("p2_4");
fact local@p2("p2_5");
fact local@p2("p2_6");
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
        {:extcopy_at_p2=>[]},
        {:local_at_p2=>
            [{:atom1=>"p2_3"},
            {:atom1=>"p2_4"},
            {:atom1=>"p2_5"},
            {:atom1=>"p2_6"},
            {:atom1=>"jointuple"}]},
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
    assert_equal(["rule copy2_at_p1($X) :- local_at_p2($X);",
        "rule copy2@p1($X) :- local@p2($X);"],
      wl_peer[1].wl_program.rule_mapping.values.map do |ar|
        if ar.first.is_a? WLBud::WLRule
          ar.first.show_wdl_format
        else
          ar.first
        end      
      end)
    # check that all collection are empty
    assert_equal([{:chan=>[]},
        {:copy2_at_p1=>[]},
        {:local_at_p1=>
            [{:atom1=>"p1_2"},
            {:atom1=>"p1_3"},
            {:atom1=>"p1_4"},
            {:atom1=>"p1_5"},
            {:atom1=>"jointuple"}]},
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
    

    # fire p2 to install the delegation
    wl_peer[2].tick
    # check that there is one new rule installed
    assert_equal(["rule copy2_at_p1($X) :- local_at_p2($X);"],
      wl_peer[2].wl_program.rule_mapping.values.map do |ar|
        if ar.first.is_a? WLBud::WLRule
          ar.first.show_wdl_format
        else
          ar.first
        end
      end)
    # check that all collection are empty
    assert_equal([{:chan=>[]},
        {:extcopy_at_p2=>[]},
        {:local_at_p2=>
            [{:atom1=>"p2_3"},
            {:atom1=>"p2_4"},
            {:atom1=>"p2_5"},
            {:atom1=>"p2_6"},
            {:atom1=>"jointuple"}]},
        {:sbuffer=>
            [{:dst=>"localhost:11111", :rel_name=>"copy2_at_p1", :fact=>["p2_3"]},
            {:dst=>"localhost:11111", :rel_name=>"copy2_at_p1", :fact=>["p2_4"]},
            {:dst=>"localhost:11111", :rel_name=>"copy2_at_p1", :fact=>["p2_5"]},
            {:dst=>"localhost:11111", :rel_name=>"copy2_at_p1", :fact=>["p2_6"]},
            {:dst=>"localhost:11111",
              :rel_name=>"copy2_at_p1",
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
    # there is no new rules only the remember that we made a delegation
    assert_equal(["rule copy2_at_p1($X) :- local_at_p2($X);",
        "rule copy2@p1($X) :- local@p2($X);"],
      wl_peer[1].wl_program.rule_mapping.values.map do |ar|
        if ar.first.is_a? WLBud::WLRule
          ar.first.show_wdl_format
        else
          ar.first
        end
      end)
    # but there are new facts thanks to the result of evaluating the delegation
    assert_equal([{:chan=>[]},
        {:copy2_at_p1=>
            [{:atom1=>"p2_3"},
            {:atom1=>"p2_4"},
            {:atom1=>"p2_5"},
            {:atom1=>"p2_6"},
            {:atom1=>"jointuple"}]},
        {:local_at_p1=>
            [{:atom1=>"p1_2"},
            {:atom1=>"p1_3"},
            {:atom1=>"p1_4"},
            {:atom1=>"p1_5"},
            {:atom1=>"jointuple"}]},
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


    # fire p0 to send all the delegation
    wl_peer[0].tick
    # fire p1 and p2 to process the delegation
    wl_peer[1].tick
    wl_peer[2].tick
    # check the status of p0
    wl_peer[0].tick
    # there is no new rules only the remember that we made a delegation
    assert_equal(["rule join_delegated_at_p0($x) :- local_at_p0($x), local_at_p1($x), local_at_p2($x);",
        "rule copy1_at_p0($X) :- local_at_p1($X);",
        "rule copy2_at_p0($X) :- local_at_p2($X);",
        "rule extcopy_at_p2($X) :- local_at_p1($X);",
        "rule deleg_from_p0_1_1_at_p1($x) :- local_at_p0($x);",
        "rule join_delegated@p0($x):-deleg_from_p0_1_1@p1($x),local@p1($x),local@p2($x);",
        "rule copy1@p0($X) :- local@p1($X);",
        "rule copy2@p0($X) :- local@p2($X);",
        "rule extcopy@p2($X) :- local@p1($X);"],
      wl_peer[0].wl_program.rule_mapping.values.map do |ar|
        if ar.first.is_a? WLBud::WLRule
          ar.first.show_wdl_format
        else
          ar.first
        end
      end)
    # but there are new facts thanks to the result of evaluating the delegation
    assert_equal([{:chan=>[]},
        {:copy1_at_p0=> # delegation to p1
            [{:atom1=>"p1_2"},
            {:atom1=>"p1_3"},
            {:atom1=>"p1_4"},
            {:atom1=>"p1_5"},
            {:atom1=>"jointuple"}]},
        {:copy2_at_p0=> # delegation to p2
            [{:atom1=>"p2_3"},
            {:atom1=>"p2_4"},
            {:atom1=>"p2_5"},
            {:atom1=>"p2_6"},
            {:atom1=>"jointuple"}]},
        {:deleg_from_p0_1_1_at_p1=>[]}, # intermediary for delegation
        {:join_delegated_at_p0=>[{:atom1=>"jointuple"}]}, # join across two peers
        {:local_at_p0=> # base fact at p0
            [{:atom1=>"1"},
            {:atom1=>"2"},
            {:atom1=>"3"},
            {:atom1=>"4"},
            {:atom1=>"jointuple"}]},
        {:sbuffer=> # send buffer
            [{:dst=>"localhost:11111",
              :rel_name=>"deleg_from_p0_1_1_at_p1",
              :fact=>["1"]},
            {:dst=>"localhost:11111",
              :rel_name=>"deleg_from_p0_1_1_at_p1",
              :fact=>["2"]},
            {:dst=>"localhost:11111",
              :rel_name=>"deleg_from_p0_1_1_at_p1",
              :fact=>["3"]},
            {:dst=>"localhost:11111",
              :rel_name=>"deleg_from_p0_1_1_at_p1",
              :fact=>["4"]},
            {:dst=>"localhost:11111",
              :rel_name=>"deleg_from_p0_1_1_at_p1",
              :fact=>["jointuple"]}]}],
      wl_peer[0].app_tables.map { |item| item.tabname }.sort.map { |at|
        tab = wl_peer[0].tables[at].map { |t|
          h = Hash[t.each_pair.to_a]
          h.delete(:wdl_rule_id)
          h.delete(:port)
          h
        }
        Hash[at, tab]
      }
    )

    # check that the fully non-local rule from p0:
    # rule extcopy@p2($X) :- local@p1($X);
    #
    # has been installed on p1
    assert_equal(["rule copy2_at_p1($X) :- local_at_p2($X);",
        "rule copy2@p1($X) :- local@p2($X);",
        "rule join_delegated_at_p0($x) :- deleg_from_p0_1_1_at_p1($x), local_at_p1($x), local_at_p2($x);",
        "rule deleg_from_p1_2_1_at_p2($x) :- deleg_from_p0_1_1_at_p1($x), local_at_p1($x);",
        "rule join_delegated@p0($x):-deleg_from_p1_2_1@p2($x),local@p2($x);",
        "rule copy1_at_p0($X) :- local_at_p1($X);",
        "rule extcopy_at_p2($X) :- local_at_p1($X);"],
      wl_peer[1].wl_program.rule_mapping.values.map do |ar|
        if ar.first.is_a? WLBud::WLRule
          ar.first.show_wdl_format
        else
          ar.first
        end
      end)
    # check facts on p2
    assert_equal([{:chan=>[]},
        {:deleg_from_p1_2_1_at_p2=>[{:deleg_from_p1_2_1_x_0=>"jointuple"}]}, # join across tuples
        {:extcopy_at_p2=> # result of fully non-local rule from p0 to p1 generating fact for p2
            [{:atom1=>"p1_2"},
            {:atom1=>"p1_3"},
            {:atom1=>"p1_4"},
            {:atom1=>"p1_5"},
            {:atom1=>"jointuple"}]},
        {:local_at_p2=> # base facts on p2
            [{:atom1=>"p2_3"},
            {:atom1=>"p2_4"},
            {:atom1=>"p2_5"},
            {:atom1=>"p2_6"},
            {:atom1=>"jointuple"}]},
        {:sbuffer=> # send buffer check
            [{:dst=>"localhost:11111", :rel_name=>"copy2_at_p1", :fact=>["p2_3"]},
            {:dst=>"localhost:11110", :rel_name=>"copy2_at_p0", :fact=>["p2_3"]},
            {:dst=>"localhost:11111", :rel_name=>"copy2_at_p1", :fact=>["p2_4"]},
            {:dst=>"localhost:11110", :rel_name=>"copy2_at_p0", :fact=>["p2_4"]},
            {:dst=>"localhost:11111", :rel_name=>"copy2_at_p1", :fact=>["p2_5"]},
            {:dst=>"localhost:11110", :rel_name=>"copy2_at_p0", :fact=>["p2_5"]},
            {:dst=>"localhost:11111", :rel_name=>"copy2_at_p1", :fact=>["p2_6"]},
            {:dst=>"localhost:11110", :rel_name=>"copy2_at_p0", :fact=>["p2_6"]},
            {:dst=>"localhost:11111", :rel_name=>"copy2_at_p1", :fact=>["jointuple"]},
            {:dst=>"localhost:11110", :rel_name=>"copy2_at_p0", :fact=>["jointuple"]},
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
      }
    )
  ensure
    wl_peer.each { |item| assert item.clear_rule_dir }
    if EventMachine::reactor_running?
      wl_peer[0..-2].each { |item| item.stop } # for all except the last
      wl_peer.last.stop(true) # for the last I also stop EM to be clean
    end
  end
  
end
