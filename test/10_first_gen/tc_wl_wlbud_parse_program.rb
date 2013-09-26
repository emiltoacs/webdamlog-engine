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
require_relative '../header_test'

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


  class Test1 < TcParseProgram
    class Test10Peer0test_relation_declaration_type < WLBud::WL
      STR0 = <<EOF
peer p1=localhost:11111;
peer p2=localhost:11112;
collection ext persistent local@p1(atom1*);
collection ext localint@p1(atom1*);
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
    class Test10Peer1test_relation_declaration_type < WLBud::WL
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
    def test_10_relation_declaration_type
      wl_peer = []
      assert_nothing_raised {wl_peer[0] = Test10Peer0test_relation_declaration_type.new('p1', Hash[WLOPTIONS0.each_pair.to_a])}
      assert_nothing_raised {wl_peer[1] = Test10Peer1test_relation_declaration_type.new('p2', Hash[WLOPTIONS1.each_pair.to_a])}

      wl_peer[0].tick
      assert(Bud::BudTable === wl_peer[0].tables.values_at(:local_at_p1).first,
        "wrong type found #{wl_peer[0].tables.values_at(:local_at_p1).first.class} expected to be include in BudTable")
    
      assert(Bud::BudScratch === wl_peer[0].tables.values_at(:localint_at_p1).first,
        "wrong type found #{wl_peer[0].tables.values_at(:localint_at_p1).first.class} expected to be include in BudScratch")

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
  end
  
  class Test20 < TcParseProgram
    class Test20Peer0test_bud_table_method_call < WLBud::WL
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
    class Test20Peer1test_bud_table_method_call < WLBud::WL
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
    def test_20_bud_table_method_call
      wl_peer = []
      assert_nothing_raised {wl_peer[0] = Test20Peer0test_bud_table_method_call.new('p1', Hash[WLOPTIONS0.each_pair.to_a])}
      assert_nothing_raised {wl_peer[1] = Test20Peer1test_bud_table_method_call.new('p2', Hash[WLOPTIONS1.each_pair.to_a])}

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
  end

  class Test30 < TcParseProgram
    class Test30WlPeer0TestRelationInitialisationWithFact < WLBud::WL
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
    class Test30WlPeer1TestRelationInitialisationWithFact < WLBud::WL
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
    def test_30_relation_initialisation_with_fact
      puts "START" if $test_verbose
      wl_peer = []
      assert_nothing_raised {wl_peer[0] = Test30WlPeer0TestRelationInitialisationWithFact.new('p1', Hash[WLOPTIONS0.each_pair.to_a])}
      assert_nothing_raised {wl_peer[1] = Test30WlPeer1TestRelationInitialisationWithFact.new('p2', Hash[WLOPTIONS1.each_pair.to_a])}
        
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
  
  class Test40 < TcParseProgram
    class Test40ParseRuleAndDisambuguiate < WLBud::WL
      STR1 = <<EOF
    peer otherguy = localhost:11111;
collection ext persistent person@local(atom1*,atom2*);
collection ext persistent friend@local(atom1*,atom2*);
collection ext persistent family@local(atom1*,atom2*);
fact family@local(0,0);
fact friend@local(1,1);
fact person@local(1,1);
fact family@local(5,5);
fact family@local(6,6);
rule person@local($id,$name) :- friend@local($id,$name);
rule person@local($id,$name) :- family@local($id,$name);
rule person@local($id,$name) :- family@otherguy($id,$name);
end
EOF
      def initialize(peername, options={})
        File.open(TEST_FILENAME1,"w"){ |file| file.write STR1}
        super(peername, TEST_FILENAME1, options)
      end
    end
    # test disambiguate peer via show_wdl_format
    def test_40_disambiguate
      wlpeer = []
      wlpeer[0] = Test40ParseRuleAndDisambuguiate.new('thisismyname')
      assert_equal ["family_at_thisismyname( 0, 0 ) ;",
        "friend_at_thisismyname( 1, 1 ) ;",
        "person_at_thisismyname( 1, 1 ) ;",
        "family_at_thisismyname( 5, 5 ) ;",
        "family_at_thisismyname( 6, 6 ) ;"], wlpeer[0].wl_program.wlfacts.map { |fact| fact.show_wdl_format }

      assert_equal [1, 2, 3, "rule person@thisismyname($id, $name) :- family@otherguy($id, $name);"],
        wlpeer[0].wl_program.rule_mapping.keys
      ar = wlpeer[0].wl_program.rule_mapping.values.first
      assert_equal "rule person_at_thisismyname($id, $name) :- friend_at_thisismyname($id, $name);", ar.first.show_wdl_format
      assert_equal ["rule person_at_thisismyname($id, $name) :- friend_at_thisismyname($id, $name);",
        "rule person_at_thisismyname($id, $name) :- family_at_thisismyname($id, $name);",
        "rule person_at_thisismyname($id, $name) :- family_at_otherguy($id, $name);",
        nil],
        wlpeer[0].wl_program.rule_mapping.values.map{ |rules| rules.first.show_wdl_format if rules.first.is_a? WLBud::WLRule }
    
    ensure
      wlpeer.each { |item| assert item.clear_rule_dir }
      if EventMachine::reactor_running?
        wlpeer[0].stop
        wlpeer[1].stop(true) # here I also stop EM to be clean
      end
    end
  end



  class Test50 < TcParseProgram
    class Test50ParseRuleAnonymousVariable < WLBud::WL
      STR1 = <<EOF
    peer otherguy = localhost:11111;
collection ext persistent person@local(atom1*,atom2*);
collection ext persistent friend@local(atom1*,atom2*);
collection ext persistent family@local(atom1*,atom2*);
collection ext persistent rating@local(_id*, rating*, owner*);
collection ext persistent picture@local(title*, owner*, _id*, image_url*);
fact family@local(0,0);
fact friend@local(1,1);
fact person@local(1,1);
fact family@local(5,5);
fact family@local(6,6);
rule person@local($id," ") :- friend@local($id,$_);
rule person@local(" ",$name) :- family@local($_,$name);
rule rating@local($id, 3, $owner):-picture@local(title, $owner, $id, url2);
end
EOF
      def initialize(peername, options={})
        File.open(TEST_FILENAME1,"w"){ |file| file.write STR1}
        super(peername, TEST_FILENAME1, options)
      end
    end
    # test disambiguate peer via show_wdl_format
    def test_50_anonymous_variable
      wlpeer = []
      wlpeer[0] = Test50ParseRuleAnonymousVariable.new('thisismyname')
      assert_equal ["family_at_thisismyname( 0, 0 ) ;",
        "friend_at_thisismyname( 1, 1 ) ;",
        "person_at_thisismyname( 1, 1 ) ;",
        "family_at_thisismyname( 5, 5 ) ;",
        "family_at_thisismyname( 6, 6 ) ;"], wlpeer[0].wl_program.wlfacts.map { |fact| fact.show_wdl_format }

      assert_equal [1, 2, 3],
        wlpeer[0].wl_program.rule_mapping.keys
      ar = wlpeer[0].wl_program.rule_mapping.values.first
      assert_equal "rule person_at_thisismyname($id, \" \") :- friend_at_thisismyname($id, $_);", ar.first.show_wdl_format
      assert_equal ["rule person_at_thisismyname($id, \" \") :- friend_at_thisismyname($id, $_);",
        "rule person_at_thisismyname(\" \", $name) :- family_at_thisismyname($_, $name);",
        "rule rating_at_thisismyname($id, 3, $owner) :- picture_at_thisismyname(title, $owner, $id, url2);"],
        wlpeer[0].wl_program.rule_mapping.values.map{ |rules| rules.first.show_wdl_format if rules.first.is_a? WLBud::WLRule }

    ensure
      wlpeer.each { |item| assert item.clear_rule_dir }
      if EventMachine::reactor_running?
        wlpeer[0].stop
        wlpeer[1].stop(true) # here I also stop EM to be clean
      end
    end
  end

end
