$:.unshift File.dirname(__FILE__)
require 'header_test'
require_relative '../lib/webdamlog_runner'

require 'test/unit'

class TcWlRunner < Test::Unit::TestCase
  include MixinTcWlTest
  
  def test_create
    pg = <<EOF
peer test_create_user=localhost:11110;
peer p1=localhost:11111;
peer p2=localhost:11112;
peer p3=localhost:11113;
collection ext persistent local@p0(atom1*);
collection ext per join_delegated@p0(atom1*);
fact local@test_create_user(1);
fact local@test_create_user(2);
fact local@test_create_user(3);
fact local@test_create_user(4);
rule join_delegated@p0($x):- local@test_create_user($x),delegated@p1($x),delegated@p2($x),delegated@p3($x);
end
EOF
    begin
      pg_file = "test_create_user_program"
      File.open(pg_file,"w"){ |file| file.write pg }
      wl_obj = nil
      assert_nothing_raised do
        wl_obj = WLRunner.create("test_create_user", "test_create_user_program", "11110")
      end
      assert_kind_of WLBud, wl_obj
      assert_kind_of WLBud::WLProgram, wl_obj.wl_program
      assert_equal 6, wl_obj.wl_program.wlpeers.size
      assert_equal 3, wl_obj.wl_program.wlcollections.size
      assert_equal 4, wl_obj.wl_program.wlfacts.size
      assert_equal 3, wl_obj.wl_program.rule_mapping.size
      assert_equal 3, wl_obj.wl_program.rule_mapping[1].size # the rule should have been split in two parts

      # original rule in position 0
      assert_kind_of WLBud::WLRule, wl_obj.wl_program.rule_mapping[1][0]
      assert_equal "rule join_delegated@p0($x):- local@test_create_user($x),delegated@p1($x),delegated@p2($x),delegated@p3($x)",
        wl_obj.wl_program.rule_mapping[1][0].text_value

      # id of local rule
      assert_equal 2, wl_obj.wl_program.rule_mapping[1][1]
      # delegated rule
      assert_equal "rule join_delegated@p0($x):-deleg_from_test_create_user_1_1@p1($x),delegated@p1($x),delegated@p2($x),delegated@p3($x);",
        wl_obj.wl_program.rule_mapping[1][2]

      # local rule rewriting
      assert_kind_of WLBud::WLRule, wl_obj.wl_program.rule_mapping[2][0]
      assert_equal "rule deleg_from_test_create_user_1_1@p1($x):-local@test_create_user($x)",
        wl_obj.wl_program.rule_mapping[2][0].text_value

      # non-local rule to delegate is not processed locally so we just keep the string describing the rule in webdamlog
      assert_equal ["rule join_delegated@p0($x):-deleg_from_test_create_user_1_1@p1($x),delegated@p1($x),delegated@p2($x),delegated@p3($x);"],
        wl_obj.wl_program.rule_mapping["rule join_delegated@p0($x):-deleg_from_test_create_user_1_1@p1($x),delegated@p1($x),delegated@p2($x),delegated@p3($x);"]

    ensure
      File.delete(pg_file) if File.exists?(pg_file)
    end
  end
end
