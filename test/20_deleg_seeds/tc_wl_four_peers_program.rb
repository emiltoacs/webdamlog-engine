$:.unshift File.dirname(__FILE__)
require_relative '../header_test'
require_relative '../../lib/webdamlog_runner'

require 'test/unit'


# Test Vera's program with four peers and variables in peer name
class TcWlFourPeersProgram < Test::Unit::TestCase
  include MixinTcWlTest
  
  PEER1NAME = "alice1"
  PEER1PORT = "10000"
  PEER2NAME = "bob2"
  PEER2PORT = "10001"
  PEER3NAME = "sue3"
  PEER3PORT = "10002"
  PEER4NAME = "peer4"
  PEER4PORT = "10003"
  PEERSPG = []
  PEERSPG << <<-EOF
peer alice1=localhost:10000;
peer bob2=localhost:10001;
peer sue3=localhost:10002;
peer peer4=localhost:10003;
collection ext per photos@alice1(img*);
collection ext per tags@alice1(img*,tag*);
collection int album_i@alice1(img*,peer*);
collection ext per friends@alice1(peer*);
fact friends@alice1("peer4");
fact friends@alice1("sue3");
fact friends@alice1("bob2");
fact photos@alice1(78);
fact tags@alice1(78,"alice1");
fact tags@alice1(78,"bob2");
  EOF
  PEERSPG << <<-EOF
peer alice1=localhost:10000;
peer bob2=localhost:10001;
peer sue3=localhost:10002;
peer peer4=localhost:10003;
collection ext per photos@bob2(img*);
collection ext per tags@bob2(img*,tag*);
collection int album_i@bob2(img*,peer*);
collection ext per friends@bob2(peer*);
fact friends@bob2("peer4");
fact friends@bob2("sue3");
fact friends@bob2("alice1");
fact photos@bob2(065);
fact tags@bob2(065,"alice1");
  EOF
  PEERSPG << <<-EOF
peer alice1=localhost:10000;
peer bob2=localhost:10001;
peer sue3=localhost:10002;
peer peer4=localhost:10003;
collection ext per photos@sue3(img*);
collection ext per tags@sue3(img*,tag*);
collection int album_i@sue3(img*,peer*);
collection ext per friends@sue3(peer*);
collection int all_friends_i@sue3(peer*);
fact friends@sue3("bob2");
fact friends@sue3("alice1");
rule all_friends_i@sue3($peer) :- friends@alice1($peer);
rule all_friends_i@sue3($peer) :- friends@bob2($peer);
rule album_i@sue3($img,$peer) :- all_friends_i@sue3($peer), photos@$peer($img), tags@$peer($img,"alice1"), tags@$peer($img,"bob2");
fact photos@sue3(75324);
fact tags@sue3(75324,"alice1");
  EOF
  PEERSPG << <<-EOF
peer alice1=localhost:10000;
peer bob2=localhost:10001;
peer sue3=localhost:10002;
peer peer4=localhost:10003;
collection ext per photos@peer4(img*);
collection ext per tags@peer4(img*,tag*);
collection int album_i@peer4(img*,peer*);
collection ext per friends@peer4(peer*);
fact photos@peer4(843);
fact photos@peer4(78);
fact photos@peer4(688);
fact photos@peer4(840);
fact photos@peer4(571);
fact photos@peer4(647);
fact photos@peer4(684);
fact photos@peer4(34);
fact photos@peer4(336);
fact photos@peer4(985);
fact photos@peer4(190);
fact photos@peer4(337);
fact photos@peer4(334);
fact photos@peer4(335);
fact photos@peer4(748);
fact tags@peer4(843,"alice1");
fact tags@peer4(843,"bob2");
fact tags@peer4(78,"alice1");
fact tags@peer4(78,"bob2");
fact tags@peer4(688,"alice1");
fact tags@peer4(840,"alice1");
fact tags@peer4(700,"bob2");
fact tags@peer4(684,"bob2");
fact tags@peer4(843,"peer4");
fact tags@peer4(840,"peer4");
fact tags@peer4(684,"peer4");
  EOF

  def setup
    # create program files
    PEERSPG.each_with_index { |pgf,index| File.open("PGFILE#{index+1}","w"){ |file| file.write pgf } }
  end

  def teardown
    # delete all Webdamlog runners
    ObjectSpace.each_object(WLRunner) do |obj|
      rule_dir = obj.rule_dir
      obj.delete
      clean_rule_dir rule_dir
    end
    Bud::stop_em_loop
    EventMachine::reactor_thread.join
    ObjectSpace.garbage_collect
  end

  # Simply test the results
  def test_results
    peers = []
    peers << WLRunner.create(PEER1NAME, "PGFILE1", PEER1PORT)
    peers << WLRunner.create(PEER2NAME, "PGFILE2", PEER2PORT)
    peers << WLRunner.create(PEER3NAME, "PGFILE3", PEER3PORT)
    peers << WLRunner.create(PEER4NAME, "PGFILE4", PEER4PORT)
    # Start alice1, bob2, peer4 without rules
    peers[0].run_engine
    peers[1].run_engine
    peers[3].run_engine
    # Start sue3 that propagate distributed its rules
    peers[2].run_engine

    peers.each { |p| p.sync_do {} }
    peers.each { |p| p.sync_do {} }
    peers.each { |p| p.sync_do {} }
    
    peers[0].sync_do do
      assert_equal [["sbuffer <= (friends_at_alice1 do |atom0|\n  [\"localhost:10002\", \"all_friends_i_at_sue3\", [atom0[0]]]\nend)"],
        ["sbuffer <= ((((deleg_from_sue3_10_1_at_alice1 * photos_at_alice1) * tags_at_alice1) * tags_at_alice1).combos(photos_at_alice1.img => (tags_at_alice1.img), photos_at_alice1.img => (tags_at_alice1.img)) do |atom0, atom1, atom2, atom3|\n  if (atom0[0] == \"true\") and ((atom2[1] == \"alice1\") and (atom3[1] == \"bob2\")) then\n    [\"localhost:10002\", \"album_i_at_sue3\", [atom1[0], \"alice1\"]]\n  end\nend)"]],
        peers[0].t_rules.pro { |t| [t.src] }
    end
    peers[1].sync_do do
      assert_equal [["sbuffer <= (friends_at_bob2 do |atom0|\n  [\"localhost:10002\", \"all_friends_i_at_sue3\", [atom0[0]]]\nend)"],
        ["sbuffer <= ((((deleg_from_sue3_8_1_at_bob2 * photos_at_bob2) * tags_at_bob2) * tags_at_bob2).combos(photos_at_bob2.img => (tags_at_bob2.img), photos_at_bob2.img => (tags_at_bob2.img)) do |atom0, atom1, atom2, atom3|\n  if (atom0[0] == \"true\") and ((atom2[1] == \"alice1\") and (atom3[1] == \"bob2\")) then\n    [\"localhost:10002\", \"album_i_at_sue3\", [atom1[0], \"bob2\"]]\n  end\nend)"]],
        peers[1].t_rules.pro { |t| [t.src] }
    end
    peers[3].sync_do do
      assert_equal [["sbuffer <= ((((deleg_from_sue3_5_1_at_peer4 * photos_at_peer4) * tags_at_peer4) * tags_at_peer4).combos(photos_at_peer4.img => (tags_at_peer4.img), photos_at_peer4.img => (tags_at_peer4.img)) do |atom0, atom1, atom2, atom3|\n  if (atom0[0] == \"true\") and ((atom2[1] == \"alice1\") and (atom3[1] == \"bob2\")) then\n    [\"localhost:10002\", \"album_i_at_sue3\", [atom1[0], \"peer4\"]]\n  end\nend)"]],
        peers[3].t_rules.pro { |t| [t.src] }
    end
    peers[2].sync_do do
      assert_equal [["seed_from_sue3_3_1_at_sue3 <= (all_friends_i_at_sue3 { |atom0| [atom0[0]] })"],
        ["sbuffer <= (seed_from_sue3_3_1_at_sue3 do |atom0|\n  if (atom0[0] == \"peer4\") then\n    [\"localhost:10003\", \"deleg_from_sue3_5_1_at_peer4\", [\"true\"]]\n  end\nend)"],
        ["album_i_at_sue3 <= ((((seed_from_sue3_3_1_at_sue3 * photos_at_sue3) * tags_at_sue3) * tags_at_sue3).combos(photos_at_sue3.img => (tags_at_sue3.img), photos_at_sue3.img => (tags_at_sue3.img)) do |atom0, atom1, atom2, atom3|\n  if (atom0[0] == \"sue3\") and ((atom2[1] == \"alice1\") and (atom3[1] == \"bob2\")) then\n    [atom1[0], \"sue3\"]\n  end\nend)"],
        ["sbuffer <= (seed_from_sue3_3_1_at_sue3 do |atom0|\n  if (atom0[0] == \"bob2\") then\n    [\"localhost:10001\", \"deleg_from_sue3_8_1_at_bob2\", [\"true\"]]\n  end\nend)"],
        ["sbuffer <= (seed_from_sue3_3_1_at_sue3 do |atom0|\n  if (atom0[0] == \"alice1\") then\n    [\"localhost:10000\", \"deleg_from_sue3_10_1_at_alice1\", [\"true\"]]\n  end\nend)"]],
        peers[2].t_rules.pro { |t| [t.src] }
    end
    peers[2].sync_do do
      assert_equal [["688", "peer4"],
        ["78", "alice1"],
        ["78", "peer4"],
        ["840", "peer4"],
        ["843", "peer4"]],
        peers[2].tables[:album_i_at_sue3].pro { |t| t.to_a }.sort
    end
  ensure
    # delete program files
    PEERSPG.each_with_index { |pgf,index| File.delete("PGFILE#{index+1}") if File.exists?("PGFILE#{index+1}") }
  end # test_results

  
  # A more detailed test to check where it has failed. Start the three peers
  # without rules then start sue3 with rules. Check that peer variables are well
  # evaluated and delegation are correctly sent and installed
  def test_four_peers_program_execution
    peers = []
    peers << WLRunner.create(PEER1NAME, "PGFILE1", PEER1PORT)
    peers << WLRunner.create(PEER2NAME, "PGFILE2", PEER2PORT)
    peers << WLRunner.create(PEER3NAME, "PGFILE3", PEER3PORT)
    peers << WLRunner.create(PEER4NAME, "PGFILE4", PEER4PORT)

    
    # Start alice1, bob2, peer4 without rules
    peers[0].run_engine
    peers[1].run_engine
    peers[3].run_engine

    # Start sue3, the peer with the rule with variable in peer names. The two
    # static rules must have generated two delegation one to alice and one to
    # bob. The dynamic rules has created a seed that will sprout at the next
    # tick
    peers[2].tick

    # check at sue3 the seed
    assert_equal [["seed_from_sue3_3_1_at_sue3 <= (all_friends_i_at_sue3 { |atom0| [atom0[0]] })"]],
      peers[2].t_rules.pro { |t| [t.src] }
    assert_equal [[
        "rule seed_from_sue3_3_1@sue3($peer) :- all_friends_i@sue3($peer);",
        "seed_from_sue3_3_1@sue3($peer)",
        "rule album_i@sue3($img, $peer):-seed_from_sue3_3_1@sue3($peer),photos@$peer($img),tags@$peer($img,\"alice1\"),tags@$peer($img,\"bob2\");",
        "rule album_i@sue3($img, $peer) :- all_friends_i@sue3($peer), photos@$peer($img), tags@$peer($img, \"alice1\"), tags@$peer($img, \"bob2\");",
        "seed_from_sue3_3_1_at_sue3"]], 
      peers[2].seed_to_sprout.map { |arr| ret = arr.map do |t|
        if t.respond_to?(:show_wdl_format, true) then t.show_wdl_format else t end
      end
      ret }
    assert_equal({}, peers[2].new_sprout_rules)
    assert_equal({}, peers[2].sprout_rules)

    # check at alice and bob the delegation received
    peers[0].sync_do do
      assert_equal [["sbuffer <= (friends_at_alice1 do |atom0|\n  [\"localhost:10002\", \"all_friends_i_at_sue3\", [atom0[0]]]\nend)"]],
        peers[0].t_rules.pro { |t| [t.src] }
    end
    peers[1].sync_do do
      assert_equal [["sbuffer <= (friends_at_bob2 do |atom0|\n  [\"localhost:10002\", \"all_friends_i_at_sue3\", [atom0[0]]]\nend)"]],
        peers[1].t_rules.pro { |t| [t.src] }
    end


    # Second execution of sue3 makes the delegations from the rules with
    # variables
    peers[2].tick   
    # check at sue3 the seed
    assert_equal [["seed_from_sue3_3_1_at_sue3 <= (all_friends_i_at_sue3 { |atom0| [atom0[0]] })"]],
      peers[2].t_rules.pro { |t| [t.src] }
    assert_equal [[
        "rule seed_from_sue3_3_1@sue3($peer) :- all_friends_i@sue3($peer);",
        "seed_from_sue3_3_1@sue3($peer)",
        "rule album_i@sue3($img, $peer):-seed_from_sue3_3_1@sue3($peer),photos@$peer($img),tags@$peer($img,\"alice1\"),tags@$peer($img,\"bob2\");",
        "rule album_i@sue3($img, $peer) :- all_friends_i@sue3($peer), photos@$peer($img), tags@$peer($img, \"alice1\"), tags@$peer($img, \"bob2\");",
        "seed_from_sue3_3_1_at_sue3"]],
      peers[2].seed_to_sprout.map { |arr| ret = arr.map do |t|
        if t.respond_to?(:show_wdl_format, true) then t.show_wdl_format else t end
      end
      ret }
    assert_equal({}, peers[2].new_sprout_rules)
    assert_equal({}, peers[2].sprout_rules)

    # check at alice and bob the delegation received
    peers[0].sync_do do
      assert_equal [["sbuffer <= (friends_at_alice1 do |atom0|\n  [\"localhost:10002\", \"all_friends_i_at_sue3\", [atom0[0]]]\nend)"]],
        peers[0].t_rules.pro { |t| [t.src] }
    end
    peers[1].sync_do do
      assert_equal [["sbuffer <= (friends_at_bob2 do |atom0|\n  [\"localhost:10002\", \"all_friends_i_at_sue3\", [atom0[0]]]\nend)"]],
        peers[1].t_rules.pro { |t| [t.src] }
    end


    # Second execution of sue3 makes the delegations from the rules with
    # variables
    peers[2].tick
    
    assert_equal(["rule album_i@sue3($img, peer4) :- seed_from_sue3_3_1@sue3(peer4), photos@peer4($img), tags@peer4($img, \"alice1\"), tags@peer4($img, \"bob2\");",
        "rule album_i@sue3($img, sue3) :- seed_from_sue3_3_1@sue3(sue3), photos@sue3($img), tags@sue3($img, \"alice1\"), tags@sue3($img, \"bob2\");",
        "rule album_i@sue3($img, bob2) :- seed_from_sue3_3_1@sue3(bob2), photos@bob2($img), tags@bob2($img, \"alice1\"), tags@bob2($img, \"bob2\");",
        "rule album_i@sue3($img, alice1) :- seed_from_sue3_3_1@sue3(alice1), photos@alice1($img), tags@alice1($img, \"alice1\"), tags@alice1($img, \"bob2\");"],
      peers[2].sprout_rules.keys)

    peers.each { |p| p.sync_do {} }
    peers.each { |p| p.sync_do {} }
    peers.each { |p| p.sync_do {} }



    # check the program of everyone after deployment
    peers[0].sync_do do
      assert_equal [["sbuffer <= (friends_at_alice1 do |atom0|\n  [\"localhost:10002\", \"all_friends_i_at_sue3\", [atom0[0]]]\nend)"],
        ["sbuffer <= ((((deleg_from_sue3_10_1_at_alice1 * photos_at_alice1) * tags_at_alice1) * tags_at_alice1).combos(photos_at_alice1.img => (tags_at_alice1.img), photos_at_alice1.img => (tags_at_alice1.img)) do |atom0, atom1, atom2, atom3|\n  if (atom0[0] == \"true\") and ((atom2[1] == \"alice1\") and (atom3[1] == \"bob2\")) then\n    [\"localhost:10002\", \"album_i_at_sue3\", [atom1[0], \"alice1\"]]\n  end\nend)"]],
        peers[0].t_rules.pro { |t| [t.src] }
    end
    peers[1].sync_do do
      assert_equal [["sbuffer <= (friends_at_bob2 do |atom0|\n  [\"localhost:10002\", \"all_friends_i_at_sue3\", [atom0[0]]]\nend)"],
        ["sbuffer <= ((((deleg_from_sue3_8_1_at_bob2 * photos_at_bob2) * tags_at_bob2) * tags_at_bob2).combos(photos_at_bob2.img => (tags_at_bob2.img), photos_at_bob2.img => (tags_at_bob2.img)) do |atom0, atom1, atom2, atom3|\n  if (atom0[0] == \"true\") and ((atom2[1] == \"alice1\") and (atom3[1] == \"bob2\")) then\n    [\"localhost:10002\", \"album_i_at_sue3\", [atom1[0], \"bob2\"]]\n  end\nend)"]],
        peers[1].t_rules.pro { |t| [t.src] }
    end
    peers[3].sync_do do
      assert_equal [["sbuffer <= ((((deleg_from_sue3_5_1_at_peer4 * photos_at_peer4) * tags_at_peer4) * tags_at_peer4).combos(photos_at_peer4.img => (tags_at_peer4.img), photos_at_peer4.img => (tags_at_peer4.img)) do |atom0, atom1, atom2, atom3|\n  if (atom0[0] == \"true\") and ((atom2[1] == \"alice1\") and (atom3[1] == \"bob2\")) then\n    [\"localhost:10002\", \"album_i_at_sue3\", [atom1[0], \"peer4\"]]\n  end\nend)"]],
        peers[3].t_rules.pro { |t| [t.src] }
    end
    peers[2].sync_do do
      assert_equal [["seed_from_sue3_3_1_at_sue3 <= (all_friends_i_at_sue3 { |atom0| [atom0[0]] })"],
        ["sbuffer <= (seed_from_sue3_3_1_at_sue3 do |atom0|\n  if (atom0[0] == \"peer4\") then\n    [\"localhost:10003\", \"deleg_from_sue3_5_1_at_peer4\", [\"true\"]]\n  end\nend)"],
        ["album_i_at_sue3 <= ((((seed_from_sue3_3_1_at_sue3 * photos_at_sue3) * tags_at_sue3) * tags_at_sue3).combos(photos_at_sue3.img => (tags_at_sue3.img), photos_at_sue3.img => (tags_at_sue3.img)) do |atom0, atom1, atom2, atom3|\n  if (atom0[0] == \"sue3\") and ((atom2[1] == \"alice1\") and (atom3[1] == \"bob2\")) then\n    [atom1[0], \"sue3\"]\n  end\nend)"],
        ["sbuffer <= (seed_from_sue3_3_1_at_sue3 do |atom0|\n  if (atom0[0] == \"bob2\") then\n    [\"localhost:10001\", \"deleg_from_sue3_8_1_at_bob2\", [\"true\"]]\n  end\nend)"],
        ["sbuffer <= (seed_from_sue3_3_1_at_sue3 do |atom0|\n  if (atom0[0] == \"alice1\") then\n    [\"localhost:10000\", \"deleg_from_sue3_10_1_at_alice1\", [\"true\"]]\n  end\nend)"]],
        peers[2].t_rules.pro { |t| [t.src] }

      assert_equal [["peer4"], ["sue3"], ["bob2"], ["alice1"]],
        peers[2].tables[:seed_from_sue3_3_1_at_sue3].pro { |t| t.to_a }

      assert_equal [["688", "peer4"],
        ["78", "alice1"],
        ["78", "peer4"],
        ["840", "peer4"],
        ["843", "peer4"]],
        peers[2].tables[:album_i_at_sue3].pro { |t| t.to_a }.sort
    end

  end # test_four_peers_program_execution
  
end # TcWlFourPeersProgram



# Test Vera's program with four peers and variables in peer name
class TcWlFourPeersProgramWithoutSelfJoin < Test::Unit::TestCase
  include MixinTcWlTest

  PEER1NAME = "alice1"
  PEER1PORT = "10000"
  PEER2NAME = "bob2"
  PEER2PORT = "10001"
  PEER3NAME = "sue3"
  PEER3PORT = "10002"
  PEER4NAME = "peer4"
  PEER4PORT = "10003"

  PEERSPG = []
  PEERSPG << <<-EOF
peer alice1=localhost:10000;
peer bob2=localhost:10001;
peer sue3=localhost:10002;
peer peer4=localhost:10003;
collection ext per photos@alice1(img*);
collection ext per tags@alice1(img*,tag*);
collection int album_i@alice1(img*,peer*);
collection ext per friends@alice1(peer*);
fact friends@alice1("peer4");
fact friends@alice1("sue3");
fact friends@alice1("bob2");
fact photos@alice1(78);
fact tags@alice1(78,"alice1");
  EOF
  PEERSPG << <<-EOF
peer alice1=localhost:10000;
peer bob2=localhost:10001;
peer sue3=localhost:10002;
peer peer4=localhost:10003;
collection ext per photos@bob2(img*);
collection ext per tags@bob2(img*,tag*);
collection int album_i@bob2(img*,peer*);
collection ext per friends@bob2(peer*);
fact friends@bob2("peer4");
fact friends@bob2("sue3");
fact friends@bob2("alice1");
fact photos@bob2(065);
fact tags@bob2(065,"alice1");
  EOF
  PEERSPG << <<-EOF
peer alice1=localhost:10000;
peer bob2=localhost:10001;
peer sue3=localhost:10002;
peer peer4=localhost:10003;
collection ext per photos@sue3(img*);
collection ext per tags@sue3(img*,tag*);
collection int album_i@sue3(img*,peer*);
collection ext per friends@sue3(peer*);
collection int all_friends_i@sue3(peer*);
fact friends@sue3("bob2");
fact friends@sue3("alice1");
rule all_friends_i@sue3($peer) :- friends@alice1($peer);
rule all_friends_i@sue3($peer) :- friends@bob2($peer);
rule album_i@sue3($img,$peer) :- all_friends_i@sue3($peer), photos@$peer($img), tags@$peer($img,"alice1");
fact photos@sue3(75324);
fact tags@sue3(75324,"alice1");
  EOF
  PEERSPG << <<-EOF
peer alice1=localhost:10000;
peer bob2=localhost:10001;
peer sue3=localhost:10002;
peer peer4=localhost:10003;
collection ext per photos@peer4(img*);
collection ext per tags@peer4(img*,tag*);
collection int album_i@peer4(img*,peer*);
collection ext per friends@peer4(peer*);
collection ext per test_join@peer4(joined_pictures*);
fact photos@peer4(843);
fact photos@peer4(78);
fact photos@peer4(688);
fact photos@peer4(840);
fact photos@peer4(571);
fact photos@peer4(647);
fact photos@peer4(684);
fact photos@peer4(34);
fact photos@peer4(336);
fact photos@peer4(985);
fact photos@peer4(190);
fact photos@peer4(337);
fact photos@peer4(334);
fact photos@peer4(335);
fact photos@peer4(748);
fact tags@peer4(843,"alice1");
fact tags@peer4(78,"alice1");
fact tags@peer4(688,"alice1");
fact tags@peer4(840,"alice1");
fact tags@peer4(700,"alice1");
fact tags@peer4(684,"peer4");
fact tags@peer4(334,"alice1");
fact tags@peer4(660,"bob2");
fact tags@peer4(242,"alice1");
fact tags@peer4(288,"peer4");
fact tags@peer4(316,"alice1");
rule test_join@peer4($img):-photos@peer4($img), tags@peer4($img,alice1);
  EOF


  def setup
    # create program files
    PEERSPG.each_with_index { |pgf,index| File.open("PGFILE#{index+1}","w"){ |file| file.write pgf } }
  end

  def teardown
    # delete all Webdamlog runners
    ObjectSpace.each_object(WLRunner) do |obj|
      rule_dir = obj.rule_dir
      obj.delete
      clean_rule_dir rule_dir
    end
    Bud::stop_em_loop
    EventMachine::reactor_thread.join
    ObjectSpace.garbage_collect
  end

  # Simply test the results
  def test_results_without_self_join
    peers = []
    peers << WLRunner.create(PEER1NAME, "PGFILE1", PEER1PORT)
    peers << WLRunner.create(PEER2NAME, "PGFILE2", PEER2PORT)
    peers << WLRunner.create(PEER3NAME, "PGFILE3", PEER3PORT)
    peers << WLRunner.create(PEER4NAME, "PGFILE4", PEER4PORT)
    # Start alice1, bob2, peer4 without rules
    peers[0].run_engine
    peers[1].run_engine
    peers[3].run_engine
    # Start sue3 that propagate distributed its rules
    peers[2].run_engine

    peers.each { |p| p.sync_do {} }
    peers.each { |p| p.sync_do {} }
    peers.each { |p| p.sync_do {} }

    peers[0].sync_do do
      assert_equal [["sbuffer <= (friends_at_alice1 do |atom0|\n  [\"localhost:10002\", \"all_friends_i_at_sue3\", [atom0[0]]]\nend)"],
        ["sbuffer <= (((deleg_from_sue3_10_1_at_alice1 * photos_at_alice1) * tags_at_alice1).combos(photos_at_alice1.img => (tags_at_alice1.img)) do |atom0, atom1, atom2|\n  if (atom0[0] == \"true\") and (atom2[1] == \"alice1\") then\n    [\"localhost:10002\", \"album_i_at_sue3\", [atom1[0], \"alice1\"]]\n  end\nend)"]],
        peers[0].t_rules.pro { |t| [t.src] }
    end
    peers[1].sync_do do
      assert_equal [["sbuffer <= (friends_at_bob2 do |atom0|\n  [\"localhost:10002\", \"all_friends_i_at_sue3\", [atom0[0]]]\nend)"],
        ["sbuffer <= (((deleg_from_sue3_8_1_at_bob2 * photos_at_bob2) * tags_at_bob2).combos(photos_at_bob2.img => (tags_at_bob2.img)) do |atom0, atom1, atom2|\n  if (atom0[0] == \"true\") and (atom2[1] == \"alice1\") then\n    [\"localhost:10002\", \"album_i_at_sue3\", [atom1[0], \"bob2\"]]\n  end\nend)"]],
        peers[1].t_rules.pro { |t| [t.src] }
    end
    peers[3].sync_do do
      assert_equal [["test_join_at_peer4 <= ((photos_at_peer4 * tags_at_peer4).combos(photos_at_peer4.img => (tags_at_peer4.img)) do |atom0, atom1|\n  [atom0[0]] if (atom1[1] == \"alice1\")\nend)"],
        ["sbuffer <= (((deleg_from_sue3_5_1_at_peer4 * photos_at_peer4) * tags_at_peer4).combos(photos_at_peer4.img => (tags_at_peer4.img)) do |atom0, atom1, atom2|\n  if (atom0[0] == \"true\") and (atom2[1] == \"alice1\") then\n    [\"localhost:10002\", \"album_i_at_sue3\", [atom1[0], \"peer4\"]]\n  end\nend)"]],
        peers[3].t_rules.pro { |t| [t.src] }
      assert_equal([["334"], ["688"], ["78"], ["840"], ["843"]],
        peers[3].tables[:test_join_at_peer4].pro { |t| t.to_a }.sort)
    end
    peers[2].sync_do do
      assert_equal [["seed_from_sue3_3_1_at_sue3 <= (all_friends_i_at_sue3 { |atom0| [atom0[0]] })"],
        ["sbuffer <= (seed_from_sue3_3_1_at_sue3 do |atom0|\n  if (atom0[0] == \"peer4\") then\n    [\"localhost:10003\", \"deleg_from_sue3_5_1_at_peer4\", [\"true\"]]\n  end\nend)"],
        ["album_i_at_sue3 <= (((seed_from_sue3_3_1_at_sue3 * photos_at_sue3) * tags_at_sue3).combos(photos_at_sue3.img => (tags_at_sue3.img)) do |atom0, atom1, atom2|\n  [atom1[0], \"sue3\"] if (atom0[0] == \"sue3\") and (atom2[1] == \"alice1\")\nend)"],
        ["sbuffer <= (seed_from_sue3_3_1_at_sue3 do |atom0|\n  if (atom0[0] == \"bob2\") then\n    [\"localhost:10001\", \"deleg_from_sue3_8_1_at_bob2\", [\"true\"]]\n  end\nend)"],
        ["sbuffer <= (seed_from_sue3_3_1_at_sue3 do |atom0|\n  if (atom0[0] == \"alice1\") then\n    [\"localhost:10000\", \"deleg_from_sue3_10_1_at_alice1\", [\"true\"]]\n  end\nend)"]],
        peers[2].t_rules.pro { |t| [t.src] }
      assert_equal([["alice1"], ["bob2"], ["peer4"], ["sue3"]],
        peers[2].tables[:seed_from_sue3_3_1_at_sue3].pro { |t| t.to_a }.sort)
      assert_equal([["alice1"], ["bob2"], ["peer4"], ["sue3"]],
        peers[2].tables[:all_friends_i_at_sue3].pro { |t| t.to_a }.sort)
    end

    peers[2].sync_do do
      assert_equal([["065", "bob2"],
          ["334", "peer4"],
          ["688", "peer4"],
          ["75324", "sue3"],
          ["78", "alice1"],
          ["78", "peer4"],
          ["840", "peer4"],
          ["843", "peer4"]],
        peers[2].tables[:album_i_at_sue3].pro { |t| t.to_a }.sort)
    end
  ensure
    # delete program files
    PEERSPG.each_with_index { |pgf,index| File.delete("PGFILE#{index+1}") if File.exists?("PGFILE#{index+1}") }
  end # test_results
end #