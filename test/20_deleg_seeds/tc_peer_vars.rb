$:.unshift File.dirname(__FILE__)
require_relative '../header_test'
require_relative '../../lib/webdamlog_runner'

require 'test/unit'

# Exhibit the problem with bud self-joins that works only alone that is without
# other joins in the rule
class TcPeerVars < Test::Unit::TestCase
  include MixinTcWlTest

  def setup
    @pg1 = <<-EOF
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
end
    EOF
    @username1 = "alice1"
    @port1 = "10000"
    @pg_file1 = "test_peer_vars_1_program"
    File.open(@pg_file1,"w"){ |file| file.write @pg1 }

    @pg2 = <<-EOF
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
end
    EOF
    @username2 = "bob2"
    @port2 = "10001"
    @pg_file2 = "test_peer_vars_2_program"
    File.open(@pg_file2,"w"){ |file| file.write @pg2 }

    @pg3 = <<-EOF
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
end
    EOF
    @username3 = "sue3"
    @port3 = "10002"
    @pg_file3 = "test_peer_vars_3_program"
    File.open(@pg_file3,"w"){ |file| file.write @pg3 }

    @pg4 = <<-EOF
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
end
    EOF
    @username4 = "peer4"
    @port4 = "10003"
    @pg_file4 = "test_peer_vars_4_program"
    File.open(@pg_file4,"w"){ |file| file.write @pg4 }
  end

  def teardown
    ObjectSpace.each_object(WLRunner){ |obj| obj.delete }
    ObjectSpace.garbage_collect
  end

  # This test shows clearly that self-joins in bud works only if there is only
  # one join in the rule that is only the self join. Comment the clear_rule_dir
  # methods in the ensure block to check the bud rules and see by yourself
  def test_peer_vars
    begin
      runner1 = nil
      runner2 = nil
      runner3 = nil
      runner4 = nil
      assert_nothing_raised do
        runner1 = WLRunner.create(@username1, @pg_file1, @port1)
        runner2 = WLRunner.create(@username2, @pg_file2, @port2)
        runner3 = WLRunner.create(@username3, @pg_file3, @port3)
        runner4 = WLRunner.create(@username4, @pg_file4, @port4)
      end

      runner1.tick
      runner2.tick
      runner4.tick
      runner3.tick

      runner1.tick
      runner2.tick
      runner4.tick
      runner3.tick

      runner1.tick
      runner2.tick
      runner4.tick
      runner3.tick

      runner1.tick
      runner2.tick
      runner4.tick
      runner3.tick

      runner1.tick
      runner2.tick
      runner4.tick
      runner3.tick

      puts "Snapshot: "
      puts runner3.tables[:album_i_at_sue3].sort

      # This shows that the content of album@sue is exactly the the one with the
      # tags alice1 without paying attention to tag bob2
      assert_equal runner4.tables[:tags_at_peer4].pro{|t| t[0] if t[1]=="alice1"}.sort,
        runner3.tables[:album_i_at_sue3].pro{|t| t[0]}.sort

      # The content of album@sue is deterministic. The rules are well deployed
      # and rewritten however the second joins in the self-join is silently
      # ignored by bud
      assert_equal [["120", "peer4"],
        ["2", "peer4"],
        ["234", "peer4"],
        ["242", "peer4"],
        ["260", "peer4"],
        ["277", "peer4"],
        ["316", "peer4"],
        ["334", "peer4"],
        ["335", "peer4"],
        ["336", "peer4"],
        ["337", "peer4"],
        ["34", "peer4"],
        ["373", "peer4"],
        ["391", "peer4"],
        ["40", "peer4"],
        ["442", "peer4"],
        ["467", "peer4"],
        ["496", "peer4"],
        ["499", "peer4"],
        ["516", "peer4"],
        ["529", "peer4"],
        ["538", "peer4"],
        ["546", "peer4"],
        ["582", "peer4"],
        ["610", "peer4"],
        ["630", "peer4"],
        ["647", "peer4"],
        ["660", "peer4"],
        ["688", "peer4"],
        ["700", "peer4"],
        ["712", "peer4"],
        ["726", "peer4"],
        ["734", "peer4"],
        ["748", "peer4"],
        ["779", "peer4"],
        ["78", "peer4"],
        ["8", "peer4"],
        ["817", "peer4"],
        ["818", "peer4"],
        ["820", "peer4"],
        ["833", "peer4"],
        ["843", "peer4"],
        ["850", "peer4"],
        ["889", "peer4"],
        ["90", "peer4"],
        ["910", "peer4"],
        ["937", "peer4"]],
        runner3.tables[:album_i_at_sue3].sort,
        "unexpected content in album at sue"

      ensure
      runner1.clear_rule_dir
      runner2.clear_rule_dir
      runner3.clear_rule_dir
      runner4.clear_rule_dir
      if EventMachine::reactor_running?
        runner1.stop
        runner2.stop
        runner3.stop
        runner4.stop
      end
      File.delete(@pg_file1) if File.exists?(@pg_file1)
      File.delete(@pg_file2) if File.exists?(@pg_file2)
      File.delete(@pg_file3) if File.exists?(@pg_file3)
      File.delete(@pg_file4) if File.exists?(@pg_file4)
    end
  end
end