$:.unshift File.dirname(__FILE__)
require 'header_test'
require_relative '../../lib/webdamlog_runner'

require 'test/unit'

# test create and run in {WLRunner}
class TcWl1Runner < Test::Unit::TestCase
  include MixinTcWlTest

  @pg = <<-EOF
peer test_create_user=localhost:11110;
peer p1=localhost:11111;
peer p2=localhost:11112;
peer p3=localhost:11113;
collection ext persistent local@test_create_user(atom1*);
collection ext per join_delegated@test_create_user(atom1*);
collection int local2@test_create_user(atom1*);
fact local@test_create_user(1);
fact local@test_create_user(2);
fact local@test_create_user(3);
fact local@test_create_user(4);
rule local2@test_create_user($x) :- local@test_create_user($x);
end
  EOF
  @username = "test_create_user"
  @port = "11110"
  @pg_file = "test_create_user_program"
  File.open(@pg_file,"w"){ |file| file.write @pg }

  def test_parse
    wl_obj = nil
    assert_nothing_raised do
      wl_obj = WLRunner.create(@username, @pg_file, @port)
    end
    assert_equal "rule join_delegated_at_p0($x) :- local_at_test_create_user($x), delegated_at_p1($x), delegated_at_p2($x), delegated_at_p3($x);",
      wl_obj.parse("rule join_delegated@p0($x):- local@test_create_user($x),delegated@p1($x),delegated@p2($x),delegated@p3($x);").first.show_wdl_format
    assert_equal 2,
      wl_obj.parse("collection int query1@local(title*);\nrule query1@local($title):-pictures@local($title,$_,$_,$_);").size
    assert_equal "intensional query1_at_test_create_user( title* ) ;",
      wl_obj.parse("collection int query1@local(title*);\nrule query1@local($title):-pictures@local($title,$_,$_,$_);")[0].show_wdl_format
    assert_equal "rule query1_at_test_create_user($title) :- pictures_at_test_create_user($title, $_, $_, $_);",
      wl_obj.parse("collection int query1@local(title*);\nrule query1@local($title):-pictures@local($title,$_,$_,$_);")[1].show_wdl_format    
  end # test_parse
end # class TcWl1Runner

# test create and run in {WLRunner}
class TcWl1Runner < Test::Unit::TestCase
  include MixinTcWlTest

  def setup
    @pg = <<-EOF
peer test_create_user=localhost:11110;
peer p1=localhost:11111;
peer p2=localhost:11112;
peer p3=localhost:11113;
collection ext persistent local@test_create_user(atom1*);
collection ext per join_delegated@test_create_user(atom1*);
collection int local2@test_create_user(atom1*);
fact local@test_create_user(1);
fact local@test_create_user(2);
fact local@test_create_user(3);
fact local@test_create_user(4);
rule join_delegated@p0($x):- local@test_create_user($x),delegated@p1($x),delegated@p2($x),delegated@p3($x);
rule local2@test_create_user($x) :- local@test_create_user($x);
end
    EOF
    @username = "test_create_user"
    @port = "11110"
    @pg_file = "test_create_user_program"
    File.open(@pg_file,"w"){ |file| file.write @pg }
  end

  def teardown    
    ObjectSpace.each_object(WLRunner){ |obj| obj.delete }
    ObjectSpace.garbage_collect
  end

  def test_create
    begin
      wl_obj = nil
      assert_nothing_raised do
        wl_obj = WLRunner.create(@username, @pg_file, @port)
      end
      assert_kind_of WLBud, wl_obj
      assert_kind_of WLBud::WLProgram, wl_obj.wl_program
      assert_equal 4, wl_obj.wl_program.wlpeers.size
      assert_equal 4, wl_obj.wl_program.wlcollections.size
      assert_equal 4, wl_obj.wl_program.wlfacts.size
      assert_equal 4, wl_obj.wl_program.rule_mapping.size
      assert_equal 3, wl_obj.wl_program.rule_mapping[1].size # the rule should have been split in two parts

      # original rule in position 0
      assert_kind_of WLBud::WLRule, wl_obj.wl_program.rule_mapping[1][0]
      assert_equal "rule join_delegated@p0($x):- local@test_create_user($x),delegated@p1($x),delegated@p2($x),delegated@p3($x)",
        wl_obj.wl_program.rule_mapping[1][0].text_value

      # id of local rule
      assert_equal 3, wl_obj.wl_program.rule_mapping[1][1]
      # delegated rule
      assert_equal "rule join_delegated@p0($x):-deleg_from_test_create_user_1_1@p1($x),delegated@p1($x),delegated@p2($x),delegated@p3($x);",
        wl_obj.wl_program.rule_mapping[1][2]

      # second of initial program fully local -> no-rewriting
      assert_kind_of WLBud::WLRule, wl_obj.wl_program.rule_mapping[2][0]
      assert_equal "rule local2@test_create_user($x) :- local@test_create_user($x)",
        wl_obj.wl_program.rule_mapping[2][0].text_value

      # local rule rewriting
      assert_kind_of WLBud::WLRule, wl_obj.wl_program.rule_mapping[3][0]
      assert_equal "rule deleg_from_test_create_user_1_1@p1($x):-local@test_create_user($x)",
        wl_obj.wl_program.rule_mapping[3][0].text_value

      # non-local rule to delegate is not processed locally so we just keep the
      # string describing the rule in webdamlog
      assert_equal ["rule join_delegated@p0($x):-deleg_from_test_create_user_1_1@p1($x),delegated@p1($x),delegated@p2($x),delegated@p3($x);"],
        wl_obj.wl_program.rule_mapping["rule join_delegated@p0($x):-deleg_from_test_create_user_1_1@p1($x),delegated@p1($x),delegated@p2($x),delegated@p3($x);"]

    ensure
      wl_obj.stop
      File.delete(@pg_file) if File.exists?(@pg_file)
    end
  end # test_create

  def test_run
    begin
      runner = WLRunner.create(@username, @pg_file, @port)
      assert_kind_of Integer, runner.port, "port method should return the port on which webdamlog is listening"
      assert_equal 11110, runner.port
      runner.run_engine
      assert runner.running_async
      assert_equal 19, runner.tables.size
      assert_not_nil runner.tables[:local2_at_test_create_user]
      assert_equal 4, runner.tables[:local2_at_test_create_user].to_a.size
    ensure
      runner.stop
      File.delete(@pg_file) if File.exists?(@pg_file)
    end
  end # test_run  
end # class TcWlRunner



class SnapshotTester < Test::Unit::TestCase
  include MixinTcWlTest

  def setup
    @pg = <<-EOF
peer p1=localhost:11111;
peer p2=localhost:11112;
peer p3=localhost:11113;
collection ext persistent local@local(atom1*);
collection ext per join_delegated@local(atom1*);
collection int local2@local(atom1*);
fact local@local(1);
fact local@local(2);
fact local@local(3);
fact local@local(4);
rule join_delegated@p0($x):- local@local($x),delegated@p1($x),delegated@p2($x),delegated@p3($x);
rule local2@local($x) :- local@local($x);
end
    EOF
    @username = "test_snapshot_collection"
    @port = "11110"
    @pg_file = "test_snapshot_collection_program"
    File.open(@pg_file,"w"){ |file| file.write @pg }
  end

  def teardown
    ObjectSpace.each_object(WLRunner){ |obj| obj.delete }
    ObjectSpace.garbage_collect
  end

  def test_snapshot_collections
    wl_obj = nil
    assert_nothing_raised do
      wl_obj = WLRunner.create(@username, @pg_file, @port)
    end
    wl_obj.run_engine
    assert_equal ["extensional persitent local_at_test_snapshot_collection( atom1* ) ;",
      "extensional persitent join_delegated_at_test_snapshot_collection( atom1* ) ;",
      "intensional local2_at_test_snapshot_collection( atom1* ) ;",
      "intermediary deleg_from_test_snapshot_collection_1_1_at_p1( deleg_from_test_snapshot_collection_1_1_x_0* ) ;"],
      wl_obj.snapshot_collections
  ensure
    File.delete(@pg_file) if File.exists?(@pg_file)
  end

  def test_snapshot_peers
    wl_obj = nil
    assert_nothing_raised do
      wl_obj = WLRunner.create(@username, @pg_file, @port)
    end
    wl_obj.run_engine
    assert_equal ["test_snapshot_collection 127.0.0.1:11110",
      "p1 localhost:11111",
      "p2 localhost:11112",
      "p3 localhost:11113"],
      wl_obj.snapshot_peers
  ensure
    File.delete(@pg_file) if File.exists?(@pg_file)
  end

  def test_snapshot_rules
    wl_obj = nil
    assert_nothing_raised do
      wl_obj = WLRunner.create(@username, @pg_file, @port)
    end
    wl_obj.run_engine
    assert_equal({1=> "rule join_delegated_at_p0($x) :- local_at_test_snapshot_collection($x), delegated_at_p1($x), delegated_at_p2($x), delegated_at_p3($x);",
        2=> "rule local2_at_test_snapshot_collection($x) :- local_at_test_snapshot_collection($x);",
        3=> "rule deleg_from_test_snapshot_collection_1_1_at_p1($x) :- local_at_test_snapshot_collection($x);"},
      wl_obj.snapshot_rules)
  ensure
    File.delete(@pg_file) if File.exists?(@pg_file)
  end

  def test_snapshot_full_state
    wl_obj = nil
    assert_nothing_raised do
      wl_obj = WLRunner.create(@username, @pg_file, @port)
    end
    wl_obj.run_engine
    assert_equal([["test_snapshot_collection 127.0.0.1:11110",
          "p1 localhost:11111",
          "p2 localhost:11112",
          "p3 localhost:11113"],
        ["extensional persitent local_at_test_snapshot_collection( atom1* ) ;",
          "extensional persitent join_delegated_at_test_snapshot_collection( atom1* ) ;",
          "intensional local2_at_test_snapshot_collection( atom1* ) ;",
          "intermediary deleg_from_test_snapshot_collection_1_1_at_p1( deleg_from_test_snapshot_collection_1_1_x_0* ) ;"],
        {1=>
            "rule join_delegated_at_p0($x) :- local_at_test_snapshot_collection($x), delegated_at_p1($x), delegated_at_p2($x), delegated_at_p3($x);",
          2=>
            "rule local2_at_test_snapshot_collection($x) :- local_at_test_snapshot_collection($x);",
          3=>
            "rule deleg_from_test_snapshot_collection_1_1_at_p1($x) :- local_at_test_snapshot_collection($x);"}],
      wl_obj.snapshot_full_state)
  ensure
    File.delete(@pg_file) if File.exists?(@pg_file)
  end

  def test_snapshot_relname
    wl_obj = nil
    assert_nothing_raised do
      wl_obj = WLRunner.create(@username, @pg_file, @port)
    end
    wl_obj.run_engine
    assert_equal [:chan,
      :deleg_from_test_snapshot_collection_1_1_at_p1,
      :join_delegated_at_test_snapshot_collection,
      :local2_at_test_snapshot_collection,
      :local_at_test_snapshot_collection,
      :sbuffer], wl_obj.snapshot_relname
  ensure
    File.delete(@pg_file) if File.exists?(@pg_file)
  end

  def test_snapshot_facts
    wl_obj = nil
    assert_nothing_raised do
      wl_obj = WLRunner.create(@username, @pg_file, @port)
    end
    wl_obj.run_engine
    assert_equal [{:atom1=>"1"}, {:atom1=>"2"}, {:atom1=>"3"}, {:atom1=>"4"}],
      wl_obj.snapshot_facts(:local_at_test_snapshot_collection)
  ensure
    File.delete(@pg_file) if File.exists?(@pg_file)
  end
  
end
