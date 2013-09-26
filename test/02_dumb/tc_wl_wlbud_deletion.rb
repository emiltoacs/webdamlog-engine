#  File name tc_wl_wlbud_deletion.rb
#  Copyright © by INRIA
#
#  Contributors : Webdam Team <webdam.inria.fr>
#       Emilien Antoine <emilien[dot]antoine[@]inria[dot]fr>
#
#   WebdamLog - Jan 20, 2013
#
#   Encoding - UTF-8
$:.unshift File.dirname(__FILE__)
require_relative '../header_test'

# TODO Test the deletion of facts according to the type of relations in which it
# spreads
class TcWlWlBudDeletion < Test::Unit::TestCase
  include MixinTcWlTest

  @@first_test=true
  NUMBER_OF_TEST_PG = 2
  TEST_FILENAME_VAR = "test_filename_"
  CLASS_PEER_NAME = "PeerBudDeletion"
  PREFIX_PORT_NUMBER = "1111"

  def setup
    if @@first_test
      create_wlpeers_classes(NUMBER_OF_TEST_PG, CLASS_PEER_NAME)
      @@first_test=false
    end
    @wloptions = Struct.new :ip, :port, :wl_test
    (0..NUMBER_OF_TEST_PG-1).each do |i|
      eval("@#{TEST_FILENAME_VAR}#{i} = \"prog_#{create_name}_peer#{i}\"")
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

  def test_delta_local
    str0 = <<EOF
peer p0=localhost:11110;
peer p1=localhost:11111;
collection ext persistent local@p0(atom1*);
collection int join_ext@p0(atom1*);
fact local@p0(1);
fact local@p0(2);
fact local@p0(3);
rule join_ext@p0($x):- local@p0($x);
end
EOF
    str1 = <<EOF
peer p0=localhost:11110;
peer p1=localhost:11111;
collection ext persistent useless@p1(atom1*);
end
EOF
    wl_peer = []
    (0..NUMBER_OF_TEST_PG-1).each do |i|      
      wl_peer << eval("@@#{CLASS_PEER_NAME}#{i}.new(\'p#{i}\', str#{i}, @#{TEST_FILENAME_VAR}#{i}, Hash[@tcoption#{i}.each_pair.to_a])")
    end
    # #TODO current finish the test to try the delta according to collection
    # type in bud: use WLBud::schema_init method to force the type of the
    # collection to create ...

  ensure
    unless wl_peer.nil? or wl_peer.empty?
      wl_peer.each { |p|
        p.clear_rule_dir
        p.stop(true) if EventMachine::reactor_running?          
      }
    end
  end

  def test_delta_remote
    str0 = <<EOF
peer p0=localhost:11110;
peer p1=localhost:11111;
collection ext persistent local@p0(atom1*);
collection ext persistent join_ext@p0(atom1*);
fact local@p0(1);
fact local@p0(2);
fact local@p0(3);
fact local@p0(4);
rule join_ext@p0($x):- local@p0($x),delegated@p1($x);
end
EOF
    str1 = <<EOF
peer p0=localhost:11110;
peer p1=localhost:11111;
collection ext persistent delegated@p1(atom1*);
fact delegated@p1(0);
fact delegated@p1(3);
fact delegated@p1(4);
fact delegated@p1(5);
fact delegated@p1(6);
end
EOF
    wl_peer = []
    (0..NUMBER_OF_TEST_PG-1).each do |i|
      wl_peer << eval("@@#{CLASS_PEER_NAME}#{i}.new(\'p#{i}\', str#{i}, @#{TEST_FILENAME_VAR}#{i}, Hash[@tcoption#{i}.each_pair.to_a])")
    end

    wl_peer.reverse_each do |p|
      p.tick
    end
    assert_equal [["0"], ["3"], ["4"], ["5"], ["6"]], wl_peer[1].delegated_at_p1.to_a.sort
    unless wl_peer.nil? or wl_peer.empty?
      wl_peer.each { |p|
        p.clear_rule_dir
        p.stop(true) if EventMachine::reactor_running?
      }
    end
  end
end
