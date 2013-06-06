# Test the methods inside wlbud that are never called directly from outside to
# modify dynamically webdamlog programs

$:.unshift File.dirname(__FILE__)
require 'header_test'

require 'test/unit'

# Test dynamic facts addition
class TcWlWlbudAddFacts < Test::Unit::TestCase

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
    ObjectSpace.each_object(WLBud){ |obj| obj.stop if obj.running_async }
    ObjectSpace.garbage_collect
  end

  class KlassAddFacts < WLBud::WL; end;

  # Test add_facts in {WLBud::WL}
  def test_add_facts
    begin
      wl_obj = nil      
      assert_nothing_raised do
        wl_obj = KlassAddFacts.new(@username, @pg_file, {:port => @port})
      end
      wl_obj.run_bg
      assert_not_nil wl_obj.tables[:local_at_test_create_user]
      assert_equal 4, wl_obj.tables[:local_at_test_create_user].to_a.size
      valid, err = wl_obj.add_facts({ "local_at_test_create_user" => [["5"]] })
      assert_equal 1, valid.size
      assert_equal({"local_at_test_create_user"=>[["5"]]}, valid)
      assert_equal 0, err.size
      assert_equal({}, err)
      wl_obj.tick
      assert_equal 5, wl_obj.tables[:local_at_test_create_user].to_a.size

      valid, err = wl_obj.add_facts({ "local_at_test_create_user" => [["5", "6"], "", ["6"]] })
      assert_equal 1, valid.size
      assert_equal({"local_at_test_create_user"=>[["6"]]}, valid)
      assert_equal 2, err.size
      assert_equal(
        {["local_at_test_create_user", ["5", "6"]]=>
            "fact of arity 2 in relation local_at_test_create_user of arity 1",
          ["local_at_test_create_user", ""]=>
            "fact of arity 0 in relation local_at_test_create_user of arity 1"}, err)
      wl_obj.tick
      assert_equal 6, wl_obj.tables[:local_at_test_create_user].to_a.size
    ensure
      File.delete(@pg_file) if File.exists?(@pg_file)
    end
  end

  
end
