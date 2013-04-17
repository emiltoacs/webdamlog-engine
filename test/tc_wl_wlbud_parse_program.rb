# ####License####
#  File name tc_parse_program.rb
#  Copyright © by INRIA
# 
#  Contributors : Webdam Team <webdam.inria.fr>
#       Emilien Antoine <emilien[dot]antoine[@]inria[dot]fr>
# 
#   WebdamLog - Jul 6, 2012
# 
#   Encoding - UTF-8
# ####License####
$:.unshift File.dirname(__FILE__)
require 'header_test'

# Use to test if a wl_program object is transformed into the right bud program.
#
# Given a right wl_program objects it should generate the right bud collection.
#
# This test is the following of tc_wl_program_treetop
#
class TcParseProgram < Test::Unit::TestCase

  NUMBER_OF_TEST_PG = 2
  PREFIX_PORT_NUMBER = "1111"
  @@first_test=true

  def setup
    if @@first_test
      @@first_test=false
      wloptions = Struct.new :ip, :port
      (0..NUMBER_OF_TEST_PG-1).each do |i|
        eval("TEST_FILENAME#{i} = \"prog#{i}\"")
        eval("WLOPTIONS#{i} = wloptions.new \"localhost\", \"#{PREFIX_PORT_NUMBER}#{i}\"")
      end
    end
  end

  def teardown
    #    self.class.constants.each{ |item| p "#{item} : #{eval(item)}"if item=~/FILENAME/ }
    (0..NUMBER_OF_TEST_PG-1).each do |i|
      #      p Dir.entries((File.dirname("TEST_FILENAME#{i}"))).inspect+" in dir"
      #      p File.exist?(eval("TEST_FILENAME#{i}")).to_s+" exists?"
      #      p File.expand_path(File.dirname("TEST_FILENAME#{i}")).to_s+" dirname"
      eval("File.delete TEST_FILENAME#{i} if File.exist? TEST_FILENAME#{i}")
      #      p File.exist?(eval("TEST_FILENAME#{i}")).to_s+" exists?"
    end
  end


  class Peer0test_relation_declaration_type < WLBud::WL
    STR0 = <<EOF
peer p1=localhost:11111;
peer p2=localhost:11112;
collection ext persistent local@p1(atom1*);
collection int delegated@p2(atom1*);
fact local@p1(1);
fact local@p1(2);
fact local@p1(3);
fact local@p1(4);
end
EOF
    def initialize(peername, options={})
      File.open(TEST_FILENAME0,"w"){ |file| file.write STR0}
      super(peername, TEST_FILENAME0, options)
    end
  end
  class Peer1test_relation_declaration_type < WLBud::WL
    STR1 = <<EOF
peer p1=localhost:11111;
peer p2=localhost:11112;
collection ext persistent delegated@p2(atom1*);
fact delegated@p2(0);
fact delegated@p2(3);
fact delegated@p2(4);
fact delegated@p2(5);
end
EOF
    def initialize(peername, options={})
      File.open(TEST_FILENAME1,"w"){ |file| file.write STR1}
      super(peername, TEST_FILENAME1, options)
    end
  end

  def test_relation_declaration_type
    wl_peer = []
    assert_nothing_raised {wl_peer[0] = Peer0test_relation_declaration_type.new('p1', Hash[WLOPTIONS0.each_pair.to_a])}
    assert_nothing_raised {wl_peer[1] = Peer1test_relation_declaration_type.new('p2', Hash[WLOPTIONS1.each_pair.to_a])}

    wl_peer[0].tick
    assert(Bud::BudTable === wl_peer[0].tables.values_at(:local_at_p1).first,
      "wrong type found #{wl_peer[0].tables.values_at(:local_at_p1).first.class} expected to be include in BudTable")
    
    assert(Bud::BudScratch === wl_peer[0].tables.values_at(:delegated_at_p2).first,
      "wrong type found #{wl_peer[1].tables.values_at(:local_at_p1).first.class} expected to be include in BudScratch")

    wl_peer[1].tick
    assert(Bud::BudTable === wl_peer[1].tables.values_at(:delegated_at_p2).first,
      "wrong type found #{wl_peer[1].tables.values_at(:delegated_at_p2).first.class} expected to be include in BudTable")

  ensure
    wl_peer.each { |item| assert item.clear_rule_dir }
    if EventMachine::reactor_running?
      wl_peer[0].stop
      wl_peer[1].stop(true) # here I also stop EM to be clean
    end
  end

  

  class Peer0test_bud_table_method_call < WLBud::WL
    STR0 = <<EOF
peer p1=localhost:11111;
peer p2=localhost:11112;
collection ext persistent local@p1(atom1*);
collection int delegated@p2(atom1*);
fact local@p1(1);
fact local@p1(2);
fact local@p1(3);
fact local@p1(4);
end
EOF
    def initialize(peername, options={})
      File.open(TEST_FILENAME0,"w"){ |file| file.write STR0}
      super(peername, TEST_FILENAME0, options)
    end
  end
  class Peer1test_bud_table_method_call < WLBud::WL
    STR1 = <<EOF
peer p1=localhost:11111;
peer p2=localhost:11112;
collection ext persistent delegated@p2(atom1*);
fact delegated@p2(0);
fact delegated@p2(3);
fact delegated@p2(4);
fact delegated@p2(5);
end
EOF
    def initialize(peername, options={})
      File.open(TEST_FILENAME1,"w"){ |file| file.write STR1}
      super(peername, TEST_FILENAME1, options)
    end

  end
  def test_bud_table_method_call
    wl_peer = []
    assert_nothing_raised {wl_peer[0] = Peer0test_bud_table_method_call.new('p1', Hash[WLOPTIONS0.each_pair.to_a])}
    assert_nothing_raised {wl_peer[1] = Peer1test_bud_table_method_call.new('p2', Hash[WLOPTIONS1.each_pair.to_a])}

    wl_peer[0].tick
    assert_nothing_raised{ wl_peer[0].local_at_p1 }
    assert_nothing_raised{ wl_peer[0].delegated_at_p2 }

    assert_equal wl_peer[0].tables.values_at(:local_at_p1).first, wl_peer[0].local_at_p1
    assert_equal wl_peer[0].tables.values_at(:delegated_at_p2).first, wl_peer[0].delegated_at_p2

    wl_peer[1].tick
    assert_nothing_raised{ wl_peer[1].delegated_at_p2 }

    assert_equal wl_peer[1].tables.values_at(:delegated_at_p2).first, wl_peer[1].delegated_at_p2
    
  ensure
    wl_peer.each { |item| assert item.clear_rule_dir }
    if EventMachine::reactor_running?
      wl_peer[0].stop
      wl_peer[1].stop(true) # here I also stop EM to be clean
    end
  end



  class WlPeer0TestRelationInitialisationWithFact < WLBud::WL
    STR0 = <<EOF
peer p1=localhost:11111;
peer p2=localhost:11112;
collection ext persistent local@p1(atom1*);
collection int delegated@p2(atom1*);
fact local@p1(1);
fact local@p1(2);
fact local@p1(3);
fact local@p1(4);
end
EOF
    def initialize(peername, options={})
      File.open(TEST_FILENAME0,"w"){ |file| file.write STR0}
      super(peername, TEST_FILENAME0, options)
    end
  end
  class WlPeer1TestRelationInitialisationWithFact < WLBud::WL
    STR1 = <<EOF
peer p1=localhost:11111;
peer p2=localhost:11112;
collection ext persistent delegated@p2(atom1*);
fact delegated@p2(0);
fact delegated@p2(3);
fact delegated@p2(4);
fact delegated@p2(5);
fact delegated@p2(6);
end
EOF
    def initialize(peername, options={})
      File.open(TEST_FILENAME1,"w"){ |file| file.write STR1}
      super(peername, TEST_FILENAME1, options)
    end
  end
  def test_relation_initialisation_with_fact
    puts "START" if $test_verbose
    wl_peer = []
    assert_nothing_raised {wl_peer[0] = WlPeer0TestRelationInitialisationWithFact.new('p1', Hash[WLOPTIONS0.each_pair.to_a])}
    assert_nothing_raised {wl_peer[1] = WlPeer1TestRelationInitialisationWithFact.new('p2', Hash[WLOPTIONS1.each_pair.to_a])}
        
    wl_peer[0].class.ancestors.reverse.each do |anc|
      anc.instance_methods(false).each do |m|
        if /^__bootstrap__/.match m
          assert_equal(wl_peer[0].class, wl_peer[0].method(m.to_sym).owner,
            "bootstrap is defined in class #{wl_peer[0].method(m.to_sym).owner} instead of #{wl_peer[0].class}")
#          if RUBY_VERSION < "1.9"
#            puts wl_peer[0].method(m.to_sym).to_ruby
#          else
#            puts wl_peer[0].method(m.to_sym).to_source
#          end
        end
      end
    end

    wl_peer[1].class.ancestors.reverse.each do |anc|
      anc.instance_methods(false).each do |m|
        if /^__bootstrap__/.match m
          assert_equal(wl_peer[1].class, wl_peer[1].method(m.to_sym).owner,
            "bootstrap is defined in class #{wl_peer[1].method(m.to_sym).owner} instead of #{wl_peer[0].class}")
        end
      end
    end
    
    wl_peer[0].tick
    wl_peer[1].tick
        
    assert_equal(4, wl_peer[0].local_at_p1.length,
      "pending:#{wl_peer[0].local_at_p1.pending.inspect}
       storage:#{wl_peer[0].local_at_p1.storage.inspect}
       delta:#{wl_peer[0].local_at_p1.delta.inspect}
       new_delta:#{wl_peer[0].local_at_p1.new_delta.inspect}
       tick_delta:#{wl_peer[0].local_at_p1.tick_delta.inspect}
      ")
    assert_equal(5, wl_peer[1].delegated_at_p2.length,
      "pending:#{wl_peer[1].delegated_at_p2.pending.inspect}
       storage:#{wl_peer[1].delegated_at_p2.storage.inspect}
       delta:#{wl_peer[1].delegated_at_p2.delta.inspect}
       new_delta:#{wl_peer[1].delegated_at_p2.new_delta.inspect}
       tick_delta:#{wl_peer[1].delegated_at_p2.tick_delta.inspect}
      ")

  ensure
    wl_peer.each { |item| assert item.clear_rule_dir }
    if EventMachine::reactor_running?      
      wl_peer[0].stop
      wl_peer[1].stop(true) # here I also stop EM to be clean
    end
  end
end
