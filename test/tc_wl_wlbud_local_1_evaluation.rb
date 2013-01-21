# ####License####
#  File name tc_local_evaluation.rb
#  Copyright © by INRIA
# 
#  Contributors : Webdam Team <webdam.inria.fr>
#       Emilien Antoine <emilien[dot]antoine[@]inria[dot]fr>
# 
#   WebdamLog - Jul 10, 2012
# 
#   Encoding - UTF-8
# ####License####
$:.unshift File.dirname(__FILE__)
require 'header_test'

class TcWlLocal1Evaluation < Test::Unit::TestCase

  @@first_test=true

  NUMBER_OF_TEST_PG = 1
  TEST_FILENAME = "test_filename_"
  PREFIX_PORT_NUMBER = "1111"
  $WL_TEST = false
  $BUD_DEBUG = false

  class Peer1Local < WLBud::WL
  
    STR0 = <<EOF
peer p1=localhost:11111;
collection ext persistent local@p1(atom1*);
collection ext persistent local2@p1(atom1*);
collection ext persistent local3@p1(atom1*);
collection ext join@p1(atom1*);
collection ext join13@p1(atom1*);
fact local@p1(1);
fact local@p1(2);
fact local@p1(3);
fact local@p1(4);
fact local2@p1(3);
fact local2@p1(4);
fact local2@p1(5);
fact local2@p1(6);
fact local2@p1(7);
rule join@p1($x):- local@p1($x),local2@p1($x);
end
EOF
    def initialize(peername, options={})
      File.open("#{TEST_FILENAME}1","w"){ |file| file.write STR0}
      super(peername, "#{TEST_FILENAME}1", options)
    end
  end

  class TestLocal1 < Peer1Local; end
  class TestLocal2 < Peer1Local; end
  class TestLocal3 < Peer1Local; end
  class TestLocal4 < Peer1Local; end
  class TestLocal5 < Peer1Local; end

  def setup
    #    if @@first_test
    #      @@first_test=false
    @wloptions = Struct.new :ip, :port
    #    end
    (0..NUMBER_OF_TEST_PG-1).each do |i|
      #eval("#{TEST_FILENAME}#{i} = \"prog_#{i}\"")
      eval("@tcoption#{i} = @wloptions.new \"localhost\", \"#{PREFIX_PORT_NUMBER}#{i}\"")
    end
    assert_equal(0,
      self.class.instance_methods.select {|m| m =~ /^__bloom__.+$/}.length,
      "content: #{self.class.instance_methods.select {|m| m =~ /^__bloom__.+$/}}")
  end

  def teardown
    #    self.class.constants.each{ |item| p "#{item} : #{eval(item)}"if item=~/FILENAME/ }
    (0..NUMBER_OF_TEST_PG-1).each do |i|
      #      p Dir.entries((File.dirname("TEST_FILENAME#{i}"))).inspect+" in dir"
      #      p File.exist?(eval("TEST_FILENAME#{i}")).to_s+" exists?"
      #      p File.expand_path(File.dirname("TEST_FILENAME#{i}")).to_s+" dirname"
      eval("File.delete \"#{TEST_FILENAME}#{i}\" if File.exist? \"#{TEST_FILENAME}#{i}\"")
      #      p File.exist?(eval("TEST_FILENAME#{i}")).to_s+" exists?"
    end
  end

  def test_local_1_join
    wl_peer_1 = TestLocal1.new('p1', Hash[@tcoption0.each_pair.to_a])
    assert_equal(1,
      wl_peer_1.class.instance_methods.select {|m| m =~ /^__bloom__.+$/}.length,
      "content: #{wl_peer_1.class.instance_methods.select {|m| m =~ /^__bloom__.+$/}.inspect}")
    # p "===wl_peer_1.tick 1 test_local_join==="
    wl_peer_1.tick
    assert_equal 4, wl_peer_1.local_at_p1.length
    assert_equal [["1"], ["2"], ["3"], ["4"]], wl_peer_1.local_at_p1.to_a.sort

    assert_equal 5, wl_peer_1.local2_at_p1.length
    assert_equal [["3"], ["4"], ["5"], ["6"], ["7"]], wl_peer_1.local2_at_p1.to_a.sort

    assert_equal 2, wl_peer_1.join_at_p1.length
    assert_equal [["3"], ["4"]], wl_peer_1.join_at_p1.to_a.sort
  ensure
    if EventMachine::reactor_running?
      wl_peer_1.stop(true) # here I also stop EM to be clean      
    end
  end
  
  def test_local_2_join_after_dynamic_adding_of_facts
    wl_peer_1 = TestLocal2.new('p1', Hash[@tcoption0.each_pair.to_a])
    assert_equal(1,
      wl_peer_1.class.instance_methods.select {|m| m =~ /^__bloom__.+$/}.length,
      "content: #{wl_peer_1.class.instance_methods.select {|m| m =~ /^__bloom__.+$/}.inspect}")
    # p "===wl_peer_1.tick 1 test_local_join_after_dynamic_adding_of_facts==="
    wl_peer_1.tick
    assert_equal 4, wl_peer_1.local_at_p1.length
    assert_equal [["1"], ["2"], ["3"], ["4"]], wl_peer_1.local_at_p1.to_a.sort

    assert_equal 5, wl_peer_1.local2_at_p1.length
    assert_equal [["3"], ["4"], ["5"], ["6"], ["7"]], wl_peer_1.local2_at_p1.to_a.sort

    assert_equal 2, wl_peer_1.join_at_p1.length
    assert_equal [["3"], ["4"]], wl_peer_1.join_at_p1.to_a.sort

    wl_peer_1.tables[:chan] << ["localhost:11111",
      ["p1",
        "0",
        {"declarations"=>[],
          "facts"=>{"local_at_p1"=>[["5"]]},
          "rules"=>[]
        }
      ]
    ]

    # p "===wl_peer_1.tick 2 test_local_join_after_dynamic_adding_of_facts==="
    wl_peer_1.tick

    assert_equal 5, wl_peer_1.local_at_p1.length    
    assert_equal [["1"], ["2"], ["3"], ["4"], ["5"]], wl_peer_1.local_at_p1.to_a.sort

    assert_equal 3, wl_peer_1.join_at_p1.length
    assert_equal [["3"], ["4"], ["5"]], wl_peer_1.join_at_p1.to_a.sort
  ensure
    if EventMachine::reactor_running?
      wl_peer_1.stop(true) # here I also stop EM to be clean
    end
  end

  def test_local_3_join_after_dynamic_adding_of_rule
    wl_peer_1 = TestLocal3.new('p1', Hash[@tcoption0.each_pair.to_a])
    assert_equal(1,
      wl_peer_1.class.instance_methods.select {|m| m =~ /^__bloom__.+$/}.length,
      "content: #{wl_peer_1.class.instance_methods.select {|m| m =~ /^__bloom__.+$/}.inspect}")
    # p "===wl_peer_1.tick 1 test_local_join_after_dynamic_adding_of_rule==="
    wl_peer_1.tick

    wl_peer_1.tables[:chan] << ["localhost:11111",
      ["p1",
        "1",
        {"declarations"=>[],
          "facts"=>{"local3_at_p1"=>[["3"]]},
          "rules"=>["rule join13@p1($x):- local@p1($x),local3@p1($x);"]
        }
      ]
    ]
    # p "===wl_peer_1.tick 2 test_local_join_after_dynamic_adding_of_rule==="
    wl_peer_1.tick

    assert_equal(2,
      wl_peer_1.class.instance_methods.select {|m| m =~ /^__bloom__.+$/}.length,
      "should have two BLOOM rules now, content: #{wl_peer_1.class.instance_methods.select {|m| m =~ /^__bloom__.+$/}.inspect}")

    assert_equal 1, wl_peer_1.local3_at_p1.length
    assert_equal [["3"]], wl_peer_1.local3_at_p1.to_a.sort

    assert_equal 1, wl_peer_1.join13_at_p1.length
    assert_equal [["3"]], wl_peer_1.join13_at_p1.to_a.sort

    wl_peer_1.tables[:chan] << ["localhost:11111",
      ["p1",
        "2",
        {"declarations"=>[],
          "facts"=>{"local3_at_p1"=>[["4"],["10"]]},
          "rules"=>[]
        }
      ]
    ]
    # p "===wl_peer_1.tick 3 test_local_join_after_dynamic_adding_of_rule==="
    wl_peer_1.tick

    assert_equal 3, wl_peer_1.local3_at_p1.length
    assert_equal [["10"], ["3"], ["4"]], wl_peer_1.local3_at_p1.to_a.sort

    assert_equal 2, wl_peer_1.join13_at_p1.length
    assert_equal [["3"], ["4"]], wl_peer_1.join13_at_p1.to_a.sort
  ensure
    if EventMachine::reactor_running?
      wl_peer_1.stop(true) # here I also stop EM to be clean
    end
  end

  # Test adding a new rule with a new relation in the head
  # === Scenario
  # add two new rule:
  # * rule join13@p1($x):- local@p1($x),local3@p1($x);
  # * rule joinOfjoin@p1($x):- join@p1($x),join13@p1($x);
  # with new relation:
  # * collection joinOfjoin@p1(atom1*);
  # === Assert
  # Content of joinOfjoin is updated as soon as adding are done in childOf
  #
  def test_local_4_join_after_declaration_new_collection_and_adding_of_rule
    wl_peer_1 = TestLocal4.new('p1', Hash[@tcoption0.each_pair.to_a])
    # p "===wl_peer_1.tick 1 test_local_4 ==="
    wl_peer_1.tick
    wl_peer_1.tables[:chan] << ["localhost:11111",
      ["p1",
        "1",
        {"declarations"=>["collection ext joinOfjoin@p1(atom1*);"],
          "facts"=>{"local3_at_p1"=>[["4"],["5"]]},
          "rules"=>["rule join13@p1($x):- local@p1($x),local3@p1($x);",
            "rule joinOfjoin@p1($x):- join@p1($x),join13@p1($x);"]
        }
      ]
    ]
    # p "===wl_peer_1.tick 2 test_local_4 ==="
    wl_peer_1.tick

    assert_kind_of Bud::BudScratch, wl_peer_1.tables[:joinOfjoin_at_p1]

    assert_equal(3,
      wl_peer_1.class.instance_methods.select {|m| m =~ /^__bloom__.+$/}.length,
      "should have three BLOOM rules now, content: #{wl_peer_1.class.instance_methods.select {|m| m =~ /^__bloom__.+$/}.inspect}")

    assert_equal 4, wl_peer_1.local_at_p1.length
    assert_equal [["1"], ["2"], ["3"], ["4"]], wl_peer_1.local_at_p1.to_a.sort

    assert_equal 5, wl_peer_1.local2_at_p1.length
    assert_equal [["3"], ["4"], ["5"], ["6"], ["7"]], wl_peer_1.local2_at_p1.to_a.sort

    assert_equal 2, wl_peer_1.local3_at_p1.length
    assert_equal [["4"], ["5"]], wl_peer_1.local3_at_p1.to_a.sort

    assert_equal 2, wl_peer_1.join_at_p1.length
    assert_equal [["3"], ["4"]], wl_peer_1.join_at_p1.to_a.sort

    assert_equal 1, wl_peer_1.join13_at_p1.length
    assert_equal [["4"]], wl_peer_1.join13_at_p1.to_a.sort

    assert_equal 1, wl_peer_1.joinOfjoin_at_p1.length
    assert_equal [["4"]], wl_peer_1.joinOfjoin_at_p1.to_a.sort

    wl_peer_1.tables[:chan] << ["localhost:11111",
      ["p1",
        "2",
        {"declarations"=>[],
          "facts"=>{"local3_at_p1"=>[["3"],["4"],["10"]]},
          "rules"=>[]
        }
      ]
    ]
    # p "===wl_peer_1.tick 3 test_local_4 ==="
    wl_peer_1.tick
    assert_equal 4, wl_peer_1.local3_at_p1.length
    assert_equal [["10"], ["3"], ["4"], ["5"]], wl_peer_1.local3_at_p1.to_a.sort

    assert_equal 2, wl_peer_1.join13_at_p1.length
    assert_equal [["3"],["4"]], wl_peer_1.join13_at_p1.to_a.sort

    assert_equal 2, wl_peer_1.joinOfjoin_at_p1.length
    assert_equal [["3"],["4"]], wl_peer_1.joinOfjoin_at_p1.to_a.sort    

    assert_equal 0, wl_peer_1.tables[:chan].pending.length, "channel sending queue should be empty"
    
  ensure
    if EventMachine::reactor_running?
      wl_peer_1.stop(true) # here I also stop EM to be clean
    end
  end

  # Test adding a new rule with a new persistent relation in the head
  # === Scenario
  # add two new rule:
  # * rule join13@p1($x):- local@p1($x),local3@p1($x);
  # * rule joinOfjoin@p1($x):- join@p1($x),join13@p1($x);
  # with new relation:
  # * collection persistent joinOfjoin@p1(atom1*);
  # === Assert
  # Content of joinOfjoin is updated as soon as adding are done in childOf
  #
  def test_local_5_join_after_declaration_persitent_new_collection_and_adding_of_rule
    wl_peer_1 = TestLocal5.new('p1', Hash[@tcoption0.each_pair.to_a])
    # p "===wl_peer_1.tick 1 test_local_5_join_after_declaration_persitent_new_collection_and_adding_of_rule==="
    wl_peer_1.tick
    wl_peer_1.tables[:chan] << ["localhost:11111",
      ["p1",
        "1",
        {"declarations"=>["collection ext persistent joinOfjoin@p1(atom1*);"],
          "facts"=>{"local3_at_p1"=>[["4"],["5"]]},
          "rules"=>["rule join13@p1($x):- local@p1($x),local3@p1($x);",
            "rule joinOfjoin@p1($x):- join@p1($x),join13@p1($x);"]
        }
      ]
    ]
    # p "===wl_peer_1.tick 2 test_local_5_join_after_declaration_persitent_new_collection_and_adding_of_rule==="
    wl_peer_1.tick

    assert_kind_of Bud::BudTable, wl_peer_1.tables[:joinOfjoin_at_p1]

    assert_equal(3,
      wl_peer_1.class.instance_methods.select {|m| m =~ /^__bloom__.+$/}.length,
      "should have three BLOOM rules now, content: #{wl_peer_1.class.instance_methods.select {|m| m =~ /^__bloom__.+$/}.inspect}")

    assert_equal 4, wl_peer_1.local_at_p1.length
    assert_equal [["1"], ["2"], ["3"], ["4"]], wl_peer_1.local_at_p1.to_a.sort

    assert_equal 5, wl_peer_1.local2_at_p1.length
    assert_equal [["3"], ["4"], ["5"], ["6"], ["7"]], wl_peer_1.local2_at_p1.to_a.sort

    assert_equal 2, wl_peer_1.local3_at_p1.length
    assert_equal [["4"], ["5"]], wl_peer_1.local3_at_p1.to_a.sort

    assert_equal 2, wl_peer_1.join_at_p1.length
    assert_equal [["3"], ["4"]], wl_peer_1.join_at_p1.to_a.sort

    assert_equal 1, wl_peer_1.join13_at_p1.length
    assert_equal [["4"]], wl_peer_1.join13_at_p1.to_a.sort

    assert_equal 1, wl_peer_1.joinOfjoin_at_p1.length
    assert_equal [["4"]], wl_peer_1.joinOfjoin_at_p1.to_a.sort
    
    wl_peer_1.tables[:chan] << ["localhost:11111",
      ["p1",
        "2",
        {"declarations"=>[],
          "facts"=>{"local3_at_p1"=>[["2"],["3"],["4"],["10"]]},
          "rules"=>[]
        }
      ]
    ]
    # p "===wl_peer_1.tick 3 test_local_5_join_after_declaration_persitent_new_collection_and_adding_of_rule==="
    wl_peer_1.tick
    assert_equal 5, wl_peer_1.local3_at_p1.length
    assert_equal [["10"], ["2"], ["3"], ["4"], ["5"]], wl_peer_1.local3_at_p1.to_a.sort
    assert_equal 3, wl_peer_1.join13_at_p1.length
    assert_equal [["2"],["3"],["4"]], wl_peer_1.join13_at_p1.to_a.sort
    assert_equal 2, wl_peer_1.joinOfjoin_at_p1.length
    assert_equal [["3"],["4"]], wl_peer_1.joinOfjoin_at_p1.to_a.sort    
  ensure
    if EventMachine::reactor_running?
      wl_peer_1.clear_rule_dir
      wl_peer_1.stop(true) # here I also stop EM to be clean
    end
  end
end
