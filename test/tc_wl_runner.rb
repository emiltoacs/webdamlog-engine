$:.unshift File.dirname(__FILE__)
require 'header_test'
require_relative '../lib/webdamlog_runner'

require 'test/unit'

# test create and run in {WLRunner}
class TcWl1Runner < Test::Unit::TestCase
  include MixinTcWlTest

  def  setup
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
    #ObjectSpace.garbage_collect
  end

  def test_create
    begin     
      wl_obj = nil
      assert_nothing_raised do
        wl_obj = WLRunner.create(@username, @pg_file, @port)
      end
      assert_kind_of WLBud, wl_obj
      assert_kind_of WLBud::WLProgram, wl_obj.wl_program
      assert_equal 6, wl_obj.wl_program.wlpeers.size
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

#  def test_run
#    begin
#      runner = WLRunner.create(@username, @pg_file, @port)
#      runner.run_engine
#      assert runner.running_async
#      assert_equal 19, runner.tables.size
#      assert_not_nil runner.tables[:local2_at_test_create_user]
#      assert_equal 4, runner.tables[:local2_at_test_create_user].to_a.size
#    ensure
#      runner.stop
#      File.delete(@pg_file) if File.exists?(@pg_file)
#    end
#  end # test_run
end # class TcWlRunner

# test update_add_collection in {WLRunner}
class TcWl2AddCollection < Test::Unit::TestCase
  include MixinTcWlTest

  def  setup
    @pg = <<-EOF
peer test_add_collection = localhost:11110;
collection ext persistent local@test_add_collection(atom1*);
collection int local2@test_add_collection(atom1*);
fact local@test_add_collection(1);
fact local@test_add_collection(2);
rule local2@test_add_collection($x) :- local@test_add_collection($x);
end
    EOF
    @username = "test_add_collection"
    @port = "11110"
    @pg_file = "test_add_collection_program"
    File.open(@pg_file,"w"){ |file| file.write @pg }
  end

  def teardown
    ObjectSpace.each_object(WLRunner){ |obj| obj.delete }
    # ObjectSpace.garbage_collect
  end

  # Test add_collection in {WLBud::WL}
  def test_add_collection
    begin
      runner = nil
      assert_nothing_raised do
        runner = WLRunner.create(@username, @pg_file, @port)
      end
      runner.tick
      assert_not_nil runner.tables[:local_at_test_add_collection]
      assert_equal 2, runner.tables[:local_at_test_add_collection].to_a.size
      name, schema = nil, nil
      # #assert_nothing_raised do
      name, schema = runner.update_add_collection("collection ext persistent added@test_add_collection(field1*, field2*, field3);")
      # #end
      assert_not_nil name
      assert_not_nil schema
      assert_equal "added_at_test_add_collection", name
      assert_equal({[:field1, :field2]=>[:field3]}, schema)

      #      assert_equal 1, valid.size
      #      assert_equal({"local_at_test_create_user"=>[["5"]]}, valid)
      #      assert_equal 0, err.size
      #      assert_equal({}, err)
      #      wl_obj.tick
      #      assert_equal 5, wl_obj.tables[:local_at_test_create_user].to_a.size
      #
      #      valid, err = wl_obj.add_facts({ "local_at_test_create_user" => [["5", "6"], "", ["6"]] })
      #      assert_equal 1, valid.size
      #      assert_equal({"local_at_test_create_user"=>[["6"]]}, valid)
      #      assert_equal 2, err.size
      #      assert_equal(
      #        {["local_at_test_create_user", ["5", "6"]]=>
      #            "fact of arity 2 in relation local_at_test_create_user of arity 1",
      #          ["local_at_test_create_user", ""]=>
      #            "fact of arity 0 in relation local_at_test_create_user of arity 1"}, err)
      #      wl_obj.tick
      #      assert_equal 6, wl_obj.tables[:local_at_test_create_user].to_a.size

    ensure
      runner.stop true
      File.delete(@pg_file) if File.exists?(@pg_file)
    end
  end
end # class TcWlAddCollection 