$:.unshift File.dirname(__FILE__)
require_relative '../header_test'
require_relative '../../lib/webdamlog_runner'

require 'test/unit'

DEBUG = false unless defined?(DEBUG)

# test projection of several relations atoms without any join in bud
class TcBudProjection < Test::Unit::TestCase
  
  class BudProj
    include Bud
    
    state do
      table :local1_at_p1, [:f1]
      table :local2_at_p1, [:f1]
      table :proj_at_p1, [:f1,:f2]
    end
    bootstrap do
      local1_at_p1 <= [[1]]
      local2_at_p1 <= [[2],[3]]
    end
    bloom do
      proj_at_p1 <= (local1_at_p1 * local2_at_p1 ).combos() {|atom0, atom1| [atom0[0], atom1[0]]};
    end
  end

  def test_bud_proj
    program = BudProj.new
    program.tick
    assert_equal [[1,2],[1,3]], program.proj_at_p1.to_a.sort
  end
end

# test projection of several relations atoms without any join in webdamlog
class TcWlWlbudLocalProjection < Test::Unit::TestCase
  include MixinTcWlTest

  def setup
    @pg1 = <<-EOF
peer p1=localhost:11110;
collection ext per local1@p1(atom1*);
collection ext per local2@p1(atom1*);
collection ext per proj@p1(atom1*, atom2*);
fact local1@p1(1);
fact local2@p1(2);
fact local2@p1(3);
rule proj@p1($x,$y) :- local1@p1($x), local2@p1($y);
end
    EOF
    @username1 = "p1"
    @port1 = "11110"
    @pg_file1 = "test_tc_wl_wlbud_local_projection"
    File.open(@pg_file1,"w"){ |file| file.write @pg1 }  
  end

  def teardown
    ObjectSpace.each_object(WLRunner) do |obj|
      clean_rule_dir obj.rule_dir
      obj.delete
    end
    ObjectSpace.garbage_collect
  end

  def test_projection
    begin
      runner1 = nil
      assert_nothing_raised do
        runner1 = WLRunner.create(@username1, @pg_file1, @port1, {:accessc => false, :debug => DEBUG })
      end
      runner1.tick
      assert_equal [], runner1.tables[:proj_at_p1].map{ |t| Hash[t.each_pair.to_a] }
      assert_equal [], runner1.snapshot_facts(:proj_at_p1)
      runner1.tick
      assert_equal [{:atom1=>"1",:atom2=>"2"},{:atom1=>"1",:atom2=>"3"}], runner1.tables[:proj_at_p1].map{ |t| Hash[t.each_pair.to_a] }
      assert_equal [{:atom1=>"1",:atom2=>"2"},{:atom1=>"1",:atom2=>"3"}], runner1.snapshot_facts(:proj_at_p1)
    ensure
      File.delete(@pg_file1) if File.exists?(@pg_file1)
      if EventMachine::reactor_running?
        runner1.stop true
      end
    end # begin
  end # test_projection
  
end # class TcWlWlbudDelegationProjection


# test projection of several relations atoms without any join in webdamlog
class TcWlWlbudDelegationProjection < Test::Unit::TestCase
  include MixinTcWlTest

  def setup
    @pg1 = <<-EOF
peer p1=localhost:11110;
peer p2=localhost:11111;
collection ext per local1@p1(atom1*);
fact local1@p1(1);
rule proj@p2($x,$y) :- local1@p1($x), local2@p2($y);
end
    EOF
    @username1 = "p1"
    @port1 = "11110"
    @pg_file1 = "test_tc_wl_wlbud_delegation_projection1"
    File.open(@pg_file1,"w"){ |file| file.write @pg1 }

    @pg2 = <<-EOF
peer p1=localhost:11110;
peer p2=localhost:11111;
collection ext per local2@p2(atom1*);
collection int proj@p2(atom1*, atom2*);
fact local2@p2(2);
fact local2@p2(3);
end
    EOF
    @username2 = "p2"
    @port2 = "11111"
    @pg_file2 = "test_tc_wl_wlbud_delegation_projection2"
    File.open(@pg_file2,"w"){ |file| file.write @pg2 }
  end

  def teardown
    ObjectSpace.each_object(WLRunner) do |obj|
      clean_rule_dir obj.rule_dir
      obj.delete
    end
    ObjectSpace.garbage_collect
  end

  def test_projection_delegation
    begin
      runner1 = nil
      runner2 = nil
      assert_nothing_raised do
        runner1 = WLRunner.create(@username1, @pg_file1, @port1, {:accessc => false, :debug => DEBUG })
        runner2 = WLRunner.create(@username2, @pg_file2, @port2, {:accessc => false, :debug => DEBUG })
      end
      runner2.tick
      runner1.tick
      runner2.tick
      assert_equal [{:deleg_from_p1_1_1_x_0=>"1"}], runner2.tables[:deleg_from_p1_1_1_at_p2].map{ |t| Hash[t.each_pair.to_a] }
      assert_equal [{:atom1=>"2"}, {:atom1=>"3"}], runner2.tables[:local2_at_p2].map{ |t| Hash[t.each_pair.to_a] }
      assert_equal [{:atom1=>"1",:atom2=>"2"},{:atom1=>"1",:atom2=>"3"}], runner2.tables[:proj_at_p2].map{ |t| Hash[t.each_pair.to_a] }
      runner2.tick
      assert_equal [{:atom1=>"1",:atom2=>"2"},{:atom1=>"1",:atom2=>"3"}], runner2.tables[:proj_at_p2].map{ |t| Hash[t.each_pair.to_a] }
    ensure
      File.delete(@pg_file1) if File.exists?(@pg_file1)
      File.delete(@pg_file2) if File.exists?(@pg_file2)
      if EventMachine::reactor_running?
        runner1.stop
        runner2.stop true
      end
    end # begin
  end # test_projection

end # class TcWlWlbudDelegationProjection