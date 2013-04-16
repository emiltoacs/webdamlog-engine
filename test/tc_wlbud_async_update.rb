# To change this template, choose Tools | Templates
# and open the template in the editor.
$:.unshift File.dirname(__FILE__)
require 'header_test'

require 'test/unit'

# Test class for methods to add relations, facts and rules dynamically in a
# wlbud instance running
#
class TcWlbudAsyncUpdate < Test::Unit::TestCase
  include MixinTcWlTest

  @@first_test=true
  NUMBER_OF_TEST_PG = 1
  TEST_FILENAME_VAR = "test_filename_"
  CLASS_PEER_NAME = "Peer"
  PREFIX_PORT_NUMBER = "1111"

  STR0 = <<EOF
peer p0=localhost:11110;
collection ext persistent bootstrap@p0(atom1*);
fact bootstrap@p0(1);
fact bootstrap@p0(2);
fact bootstrap@p0(3);
fact bootstrap@p0(4);
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
      eval("@tcoption#{i} = @wloptions.new \"localhost\",
 \"#{PREFIX_PORT_NUMBER}#{i}\",\"true\"")
    end
  end

  def teardown
    (0..NUMBER_OF_TEST_PG-1).each do |i|
      eval("File.delete @#{TEST_FILENAME_VAR}#{i} if File.exist? @#{TEST_FILENAME_VAR}#{i}")
    end
  end

  # Test how to add facts and relation via the channel into a running webdamlog instance
  #
  def test_add_relation_and_facts
    begin
      wl_peer = []
      (0..NUMBER_OF_TEST_PG-1).each do |i|
        wl_peer << eval("@@Peer#{i}.new(\'p#{i}\', STR#{i}, @#{TEST_FILENAME_VAR}#{i}, Hash[@tcoption#{i}.each_pair.to_a])")
        wl_peer.each { |p| p.run_bg }
        wl_peer.each do |p|
          p.sync_do do
            p.chan << ["localhost:11110",
              ["p0", "0",
                {"rules"=>[],
                  "facts"=>{"new_rel_at_p0"=>[["1"], ["2"], ["3"], ["4"]]},
                  "declarations"=>["collection ext persistent new_rel@p0(attr1*);"]
                }]]
          end
          assert(p.tables.has_key?("new_rel_at_p0".to_sym), "new_real should have been created")
          assert_equal [["1"], ["2"], ["3"], ["4"]], p.new_rel_at_p0.to_a.sort
        end
      end
    ensure
      if EventMachine::reactor_running?
        wl_peer.each { |peer| peer.stop(true) }
      end
    end
  end

  # Test how to add rules via channel and when they are evaluated
  #
  def test_add_rules
    begin
      wl_peer = []
      (0..NUMBER_OF_TEST_PG-1).each do |i|
        wl_peer << eval("@@Peer#{i}.new(\'p#{i}\', STR#{i}, @#{TEST_FILENAME_VAR}#{i}, Hash[@tcoption#{i}.each_pair.to_a])")
        wl_peer.each { |p| p.run_bg }
        wl_peer.each do |p|
          p.sync_do do
            p.chan << ["localhost:11110",
              ["p0", "0",
                {"rules"=>["rule join@p0($X):-new_rel@p0($X),bootstrap@p0($X);"],
                  "facts"=>{"new_rel_at_p0"=>[["3"], ["4"], ["5"], ["6"]]},
                  "declarations"=>["collection ext persistent new_rel@p0(attr1*);",
                    "collection ext persistent join@p0(attr1*);"]
                }]]
          end
          assert(p.tables.has_key?("new_rel_at_p0".to_sym), "new_real should have been created")
          assert(p.tables.has_key?("join_at_p0".to_sym), "join should have been created")
          assert_equal [["3"], ["4"]], p.join_at_p0.to_a.sort
        end
      end
    ensure
      if EventMachine::reactor_running?
        wl_peer.each { |peer| peer.stop(true) }
      end
    end
  end
end
