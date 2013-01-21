# ####License####
#  File name tc_local_2_add_source_relation.rb
#  Copyright © by INRIA
# 
#  Contributors : Webdam Team <webdam.inria.fr>
#       Emilien Antoine <emilien[dot]antoine[@]inria[dot]fr>
# 
#   WebdamLog - Aug 7, 2012
# 
#   Encoding - UTF-8
# ####License####
$:.unshift File.dirname(__FILE__)
require 'header_test'

class TcWlLocal2AddSourceRelation < Test::Unit::TestCase
  include MixinTcWlTest

  @@first_test=true

  NUMBER_OF_TEST_PG = 1
  VAR_FILENAME = "test_filename_"
  PREFIX_PORT_NUMBER = "1111"
  $WL_TEST = true
  $BUD_DEBUG=false
  PATH_TO_TEST = File.expand_path(File.dirname(__FILE__))

  # Standard initialization of wl peer with a program and default ip and port
  # number
  #
  class Peer1Local2 < WLBud::WL

    STR1 = <<EOF
peer p1=localhost:11111;
collection ext persistent local@p1(atom1*);
collection ext persistent local2@p1(atom1*);
collection ext join@p1(atom1*);
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
      File.open("#{VAR_FILENAME}1","w"){ |file| file.write STR1}
      super(peername, "#{VAR_FILENAME}1", options)
    end
  end

  class Test1Local2 < Peer1Local2; end 

  def setup
    #    if @@first_test
    #      @@first_test=false
    @wloptions = Struct.new :ip, :port
    #    end
    (0..NUMBER_OF_TEST_PG-1).each do |i|
      eval("@#{VAR_FILENAME}#{i} = \"prog_#{create_name}_#{i}\"")
      eval("@tcoption#{i} = @wloptions.new \"localhost\", \"#{PREFIX_PORT_NUMBER}#{i}\"")
    end
  end

  def teardown
    #    self.class.constants.each{ |item| p "#{item} : #{eval(item)}"if item=~/FILENAME/ }
    (0..NUMBER_OF_TEST_PG-1).each do |i|
      #      p Dir.entries((File.dirname("VAR_FILENAME#{i}"))).inspect+" in dir"
      #      p File.exist?(eval("VAR_FILENAME#{i}")).to_s+" exists?"
      #      p File.expand_path(File.dirname("VAR_FILENAME#{i}")).to_s+" dirname"
      eval("File.delete @#{VAR_FILENAME}#{i} if File.exist? @#{VAR_FILENAME}#{i}")
      #      p File.exist?(eval("VAR_FILENAME#{i}")).to_s+" exists?"
    end
  end

  # Test adding a new rule with a new relation in the body
  # === Scenario
  # add a new rule:
  # * join@p1($x):- newrel@p1($x),local2@p1($x); with new relation:
  # * newrel@p1($x)
  # === Assert
  # Content of descendant is updated as soon as a change is done in childOf
  #
  # Inserting new facts in chan for a scratch has no effect since the they are
  # insert via <= which insert facts into the delta which are erased by
  # scratch.tick
  #
  def test_1_add_table_as_source_in_new_rule
    wl_peer_1 = Test1Local2.new('p1', Hash[@tcoption0.each_pair.to_a])
    # p "===wl_peer_1.tick 1 test_1 ==="
    wl_peer_1.tick
    
    assert_equal 4, wl_peer_1.local_at_p1.length
    assert_equal [["1"], ["2"], ["3"], ["4"]], wl_peer_1.local_at_p1.to_a.sort

    assert_equal 5, wl_peer_1.local2_at_p1.length
    assert_equal [["3"], ["4"], ["5"], ["6"], ["7"]], wl_peer_1.local2_at_p1.to_a.sort

    assert_equal 2, wl_peer_1.join_at_p1.length
    assert_equal [["3"], ["4"]], wl_peer_1.join_at_p1.to_a.sort

    # p "===wl_peer_1.tick 2 test_1 ==="
    # p "add a persistent relation"
    wl_peer_1.tables[:chan] << ["localhost:11111",
      ["p1",
        "1",
        {"declarations"=>["collection ext persistent newrel@p1(atom1*);"],
          "facts"=>{"newrel_at_p1"=>[["5"],["6"]]},
          "rules"=>["rule join@p1($x):- newrel@p1($x),local2@p1($x);"]
        }
      ]
    ]
    wl_peer_1.tick

    assert_kind_of Bud::BudTable, wl_peer_1.newrel_at_p1
    assert_equal 2, wl_peer_1.newrel_at_p1.length
    assert_equal [["5"],["6"]], wl_peer_1.newrel_at_p1.to_a.sort

    assert_equal 4, wl_peer_1.join_at_p1.length
    assert_equal [["3"], ["4"], ["5"], ["6"]], wl_peer_1.join_at_p1.to_a.sort

    # p "===wl_peer_1.tick 2 test_1 ==="
    # p "add a non-persistent relation"
    wl_peer_1.tables[:chan] << ["localhost:11111",
      ["p1",
        "1",
        {"declarations"=>["collection ext newscratchrel@p1(atom1*);"],
          "facts"=>{"newscratchrel_at_p1"=>[["2"],["3"]]},
          "rules"=>["rule join@p1($x):- newscratchrel@p1($x),local@p1($x);"]
        }
      ]
    ]
    wl_peer_1.tick
    # p "inserting into from chan into scratch is useless"
    assert_kind_of Bud::BudScratch, wl_peer_1.newscratchrel_at_p1
    assert_equal 0, wl_peer_1.newscratchrel_at_p1.length
    assert_equal [], wl_peer_1.newscratchrel_at_p1.to_a.sort

    assert_equal 4, wl_peer_1.join_at_p1.length
    assert_equal [["3"], ["4"], ["5"], ["6"]], wl_peer_1.join_at_p1.to_a.sort
  ensure
    if EventMachine::reactor_running?
      wl_peer_1.stop(true) # here I also stop EM to be clean
    end
  end
end
