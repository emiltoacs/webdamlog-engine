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
fact photos@peer4(288);
fact photos@peer4(889);
fact photos@peer4(700);
fact photos@peer4(481);
fact photos@peer4(40);
fact photos@peer4(538);
fact photos@peer4(608);
fact photos@peer4(680);
fact photos@peer4(242);
fact photos@peer4(85);
fact photos@peer4(202);
fact photos@peer4(128);
fact photos@peer4(771);
fact photos@peer4(582);
fact photos@peer4(671);
fact photos@peer4(372);
fact photos@peer4(373);
fact photos@peer4(779);
fact photos@peer4(630);
fact photos@peer4(937);
fact photos@peer4(833);
fact photos@peer4(2);
fact photos@peer4(445);
fact photos@peer4(734);
fact photos@peer4(239);
fact photos@peer4(277);
fact photos@peer4(0);
fact photos@peer4(442);
fact photos@peer4(546);
fact photos@peer4(5);
fact photos@peer4(120);
fact photos@peer4(234);
fact photos@peer4(8);
fact photos@peer4(731);
fact photos@peer4(824);
fact photos@peer4(260);
fact photos@peer4(59);
fact photos@peer4(766);
fact photos@peer4(57);
fact photos@peer4(967);
fact photos@peer4(316);
fact photos@peer4(660);
fact photos@peer4(820);
fact photos@peer4(21);
fact photos@peer4(365);
fact photos@peer4(416);
fact photos@peer4(363);
fact photos@peer4(726);
fact photos@peer4(559);
fact photos@peer4(819);
fact photos@peer4(516);
fact photos@peer4(100);
fact photos@peer4(220);
fact photos@peer4(754);
fact photos@peer4(657);
fact photos@peer4(391);
fact photos@peer4(850);
fact photos@peer4(752);
fact photos@peer4(658);
fact photos@peer4(224);
fact photos@peer4(816);
fact photos@peer4(817);
fact photos@peer4(818);
fact photos@peer4(90);
fact photos@peer4(499);
fact photos@peer4(496);
fact photos@peer4(910);
fact photos@peer4(610);
fact photos@peer4(908);
fact photos@peer4(712);
fact photos@peer4(298);
fact photos@peer4(467);
fact photos@peer4(714);
fact photos@peer4(396);
fact photos@peer4(529);
fact photos@peer4(254);
fact photos@peer4(422);
fact photos@peer4(592);
fact photos@peer4(255);
fact tags@peer4(712,"alice1");
fact tags@peer4(754,"peer4");
fact tags@peer4(529,"bob2");
fact tags@peer4(335,"alice1");
fact tags@peer4(700,"alice1");
fact tags@peer4(684,"peer4");
fact tags@peer4(334,"alice1");
fact tags@peer4(660,"bob2");
fact tags@peer4(242,"alice1");
fact tags@peer4(288,"peer4");
fact tags@peer4(316,"alice1");
fact tags@peer4(688,"alice1");
fact tags@peer4(910,"alice1");
fact tags@peer4(684,"bob2");
fact tags@peer4(816,"bob2");
fact tags@peer4(712,"bob2");
fact tags@peer4(817,"bob2");
fact tags@peer4(363,"peer4");
fact tags@peer4(658,"bob2");
fact tags@peer4(582,"bob2");
fact tags@peer4(288,"bob2");
fact tags@peer4(78,"bob2");
fact tags@peer4(442,"alice1");
fact tags@peer4(391,"alice1");
fact tags@peer4(608,"bob2");
fact tags@peer4(445,"bob2");
fact tags@peer4(391,"bob2");
fact tags@peer4(90,"alice1");
fact tags@peer4(538,"bob2");
fact tags@peer4(630,"alice1");
fact tags@peer4(334,"peer4");
fact tags@peer4(529,"alice1");
fact tags@peer4(840,"bob2");
fact tags@peer4(316,"bob2");
fact tags@peer4(422,"bob2");
fact tags@peer4(889,"bob2");
fact tags@peer4(734,"bob2");
fact tags@peer4(833,"peer4");
fact tags@peer4(516,"bob2");
fact tags@peer4(630,"bob2");
fact tags@peer4(779,"alice1");
fact tags@peer4(467,"alice1");
fact tags@peer4(40,"bob2");
fact tags@peer4(546,"alice1");
fact tags@peer4(937,"alice1");
fact tags@peer4(889,"alice1");
fact tags@peer4(21,"bob2");
fact tags@peer4(190,"bob2");
fact tags@peer4(2,"alice1");
fact tags@peer4(817,"alice1");
fact tags@peer4(120,"alice1");
fact tags@peer4(277,"bob2");
fact tags@peer4(833,"alice1");
fact tags@peer4(850,"peer4");
fact tags@peer4(712,"peer4");
fact tags@peer4(416,"peer4");
fact tags@peer4(647,"alice1");
fact tags@peer4(334,"bob2");
fact tags@peer4(234,"peer4");
fact tags@peer4(843,"alice1");
fact tags@peer4(120,"bob2");
fact tags@peer4(516,"alice1");
fact tags@peer4(34,"alice1");
fact tags@peer4(582,"alice1");
fact tags@peer4(608,"peer4");
fact tags@peer4(78,"peer4");
fact tags@peer4(373,"alice1");
fact tags@peer4(833,"bob2");
fact tags@peer4(908,"bob2");
fact tags@peer4(538,"alice1");
fact tags@peer4(818,"alice1");
fact tags@peer4(680,"peer4");
fact tags@peer4(21,"peer4");
fact tags@peer4(499,"alice1");
fact tags@peer4(336,"alice1");
fact tags@peer4(260,"alice1");
fact tags@peer4(57,"bob2");
fact tags@peer4(496,"alice1");
fact tags@peer4(647,"peer4");
fact tags@peer4(734,"alice1");
fact tags@peer4(372,"bob2");
fact tags@peer4(657,"bob2");
fact tags@peer4(337,"alice1");
fact tags@peer4(234,"alice1");
fact tags@peer4(202,"bob2");
fact tags@peer4(499,"bob2");
fact tags@peer4(748,"alice1");
fact tags@peer4(726,"alice1");
fact tags@peer4(78,"alice1");
fact tags@peer4(660,"alice1");
fact tags@peer4(100,"bob2");
fact tags@peer4(40,"alice1");
fact tags@peer4(559,"bob2");
fact tags@peer4(820,"alice1");
fact tags@peer4(850,"bob2");
fact tags@peer4(819,"bob2");
fact tags@peer4(850,"alice1");
fact tags@peer4(610,"alice1");
fact tags@peer4(766,"bob2");
fact tags@peer4(481,"bob2");
fact tags@peer4(610,"bob2");
fact tags@peer4(277,"alice1");
fact tags@peer4(128,"bob2");
fact tags@peer4(8,"alice1");
fact tags@peer4(824,"bob2");
fact tags@peer4(937,"peer4");
fact tags@peer4(337,"bob2");
fact tags@peer4(0,"peer4");
fact friends@peer4("sue3");
fact friends@peer4("bob2");
fact friends@peer4("alice1");
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
    
    peers[0].sync_do do
      assert_equal [["sbuffer <= (friends_at_alice1 do |atom0|\n  [\"localhost:10002\", \"all_friends_i_at_sue3\", [atom0[0]]]\nend)"],
        ["sbuffer <= ((((deleg_from_sue3_10_1_at_alice1 * photos_at_alice1) * tags_at_alice1) * tags_at_alice1).combos(photos_at_alice1.img => (tags_at_alice1.img), photos_at_alice1.img => (tags_at_alice1.img)) do |atom0, atom1, atom2, atom3|\n  if (atom0[0] == \"true\") and ((atom2[1] == \"\\\"alice1\\\"\") and (atom3[1] == \"\\\"bob2\\\"\")) then\n    [\"localhost:10002\", \"album_i_at_sue3\", [atom1[0], \"alice1\"]]\n  end\nend)"]],
        peers[0].t_rules.pro { |t| [t.src] }
    end
    peers[1].sync_do do
      assert_equal [["sbuffer <= (friends_at_bob2 do |atom0|\n  [\"localhost:10002\", \"all_friends_i_at_sue3\", [atom0[0]]]\nend)"],
        ["sbuffer <= ((((deleg_from_sue3_8_1_at_bob2 * photos_at_bob2) * tags_at_bob2) * tags_at_bob2).combos(photos_at_bob2.img => (tags_at_bob2.img), photos_at_bob2.img => (tags_at_bob2.img)) do |atom0, atom1, atom2, atom3|\n  if (atom0[0] == \"true\") and ((atom2[1] == \"\\\"alice1\\\"\") and (atom3[1] == \"\\\"bob2\\\"\")) then\n    [\"localhost:10002\", \"album_i_at_sue3\", [atom1[0], \"bob2\"]]\n  end\nend)"]],
        peers[1].t_rules.pro { |t| [t.src] }
    end
    peers[3].sync_do do
      assert_equal [["sbuffer <= ((((deleg_from_sue3_5_1_at_peer4 * photos_at_peer4) * tags_at_peer4) * tags_at_peer4).combos(photos_at_peer4.img => (tags_at_peer4.img), photos_at_peer4.img => (tags_at_peer4.img)) do |atom0, atom1, atom2, atom3|\n  if (atom0[0] == \"true\") and ((atom2[1] == \"\\\"alice1\\\"\") and (atom3[1] == \"\\\"bob2\\\"\")) then\n    [\"localhost:10002\", \"album_i_at_sue3\", [atom1[0], \"peer4\"]]\n  end\nend)"]],
        peers[3].t_rules.pro { |t| [t.src] }
    end
    # TODO check why that is empty
    peers[2].sync_do do
      assert_equal [],
        peers[2].tables[:album_i_at_sue3].pro { |t| t.to_a }
    end
  ensure
    # delete program files
    PEERSPG.each_with_index { |pgf,index| File.delete("PGFILE#{index+1}") if File.exists?("PGFILE#{index+1}") }
  end

  
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
        if t.respond_to?(:show_wdl_format, true)
          t.show_wdl_format
        else
          t
        end
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
        if t.respond_to?(:show_wdl_format, true)
          t.show_wdl_format
        else
          t
        end
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
    
    assert_equal({"rule album_i@sue3($img, peer4) :- seed_from_sue3_3_1@sue3(peer4), photos@peer4($img), tags@peer4($img, \"alice1\"), tags@peer4($img, \"bob2\");"=>
          "rule album_i@sue3($img, peer4) :- seed_from_sue3_3_1@sue3(peer4), photos@peer4($img), tags@peer4($img, \"alice1\"), tags@peer4($img, \"bob2\");",
        "rule album_i@sue3($img, sue3) :- seed_from_sue3_3_1@sue3(sue3), photos@sue3($img), tags@sue3($img, \"alice1\"), tags@sue3($img, \"bob2\");"=>
          "rule album_i@sue3($img, sue3) :- seed_from_sue3_3_1@sue3(sue3), photos@sue3($img), tags@sue3($img, \"alice1\"), tags@sue3($img, \"bob2\");",
        "rule album_i@sue3($img, bob2) :- seed_from_sue3_3_1@sue3(bob2), photos@bob2($img), tags@bob2($img, \"alice1\"), tags@bob2($img, \"bob2\");"=>
          "rule album_i@sue3($img, bob2) :- seed_from_sue3_3_1@sue3(bob2), photos@bob2($img), tags@bob2($img, \"alice1\"), tags@bob2($img, \"bob2\");",
        "rule album_i@sue3($img, alice1) :- seed_from_sue3_3_1@sue3(alice1), photos@alice1($img), tags@alice1($img, \"alice1\"), tags@alice1($img, \"bob2\");"=>
          "rule album_i@sue3($img, alice1) :- seed_from_sue3_3_1@sue3(alice1), photos@alice1($img), tags@alice1($img, \"alice1\"), tags@alice1($img, \"bob2\");"},
      peers[2].sprout_rules)

    peers.each { |p| p.sync_do {} }
    peers.each { |p| p.sync_do {} }
    peers.each { |p| p.sync_do {} }

    # check at alice and bob the delegation received
    peers[0].sync_do do
      assert_equal [["sbuffer <= (friends_at_alice1 do |atom0|\n  [\"localhost:10002\", \"all_friends_i_at_sue3\", [atom0[0]]]\nend)"],
        ["sbuffer <= ((((deleg_from_sue3_10_1_at_alice1 * photos_at_alice1) * tags_at_alice1) * tags_at_alice1).combos(photos_at_alice1.img => (tags_at_alice1.img), photos_at_alice1.img => (tags_at_alice1.img)) do |atom0, atom1, atom2, atom3|\n  if (atom0[0] == \"true\") and ((atom2[1] == \"\\\"alice1\\\"\") and (atom3[1] == \"\\\"bob2\\\"\")) then\n    [\"localhost:10002\", \"album_i_at_sue3\", [atom1[0], \"alice1\"]]\n  end\nend)"]],
        peers[0].t_rules.pro { |t| [t.src] }
    end
    peers[1].sync_do do
      assert_equal [["sbuffer <= (friends_at_bob2 do |atom0|\n  [\"localhost:10002\", \"all_friends_i_at_sue3\", [atom0[0]]]\nend)"],
        ["sbuffer <= ((((deleg_from_sue3_8_1_at_bob2 * photos_at_bob2) * tags_at_bob2) * tags_at_bob2).combos(photos_at_bob2.img => (tags_at_bob2.img), photos_at_bob2.img => (tags_at_bob2.img)) do |atom0, atom1, atom2, atom3|\n  if (atom0[0] == \"true\") and ((atom2[1] == \"\\\"alice1\\\"\") and (atom3[1] == \"\\\"bob2\\\"\")) then\n    [\"localhost:10002\", \"album_i_at_sue3\", [atom1[0], \"bob2\"]]\n  end\nend)"]],
        peers[1].t_rules.pro { |t| [t.src] }
    end
  end
  
end
