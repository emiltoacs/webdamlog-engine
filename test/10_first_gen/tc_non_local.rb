$:.unshift File.dirname(__FILE__)
require_relative '../header_test'
require_relative '../../lib/webdamlog_runner'

require 'test/unit'

DEBUG = false unless defined?(DEBUG)

class TcNonlocalRules < Test::Unit::TestCase
  include MixinTcWlTest

  def setup
    @pg1 = <<-EOF
peer p2=localhost:11111;
peer p1=localhost:11110;
collection ext per local2@p1(atom1*);
collection int local3@p1(atom1*, atom2*);
fact local2@p1(1);
fact local2@p1(2);
rule delegated1@p2($x) :- local2@p1($x);
rule delegated_join@p2($x,$y) :- local2@p1($x), local1@p2($y);
rule local3@p1($x, $y) :- local2@p1($x), local1@p2($y);
end
    EOF
    @username1 = "p1"
    @port1 = "11110"
    @pg_file1 = "p1_control_remote_rules1"
    File.open(@pg_file1,"w"){ |file| file.write @pg1 }

    @pg2 = <<-EOF
peer p2=localhost:11111;
peer p1=localhost:11110;
collection ext per local1@p2(atom1*);
collection int delegated1@p2(atom1*);
collection int delegated_join@p2(atom1*, atom2*);
fact local1@p2(3);
end
    EOF
    @username2 = "p2"
    @port2 = "11111"
    @pg_file2 = "p1_control_remote_rules2"
    File.open(@pg_file2,"w"){ |file| file.write @pg2 }
  end

  def teardown
    ObjectSpace.each_object(WLRunner) do |obj|
      clean_rule_dir obj.rule_dir
      obj.delete
    end
    ObjectSpace.garbage_collect
  end

  def test_remote_rules
    begin
      runner1 = nil
      runner2 = nil
      assert_nothing_raised do
        runner1 = WLRunner.create(@username1, @pg_file1, @port1, { :accessc => false, :debug => DEBUG })
        runner2 = WLRunner.create(@username2, @pg_file2, @port2, { :accessc => false, :debug => DEBUG })
      end

      runner2.tick
      runner1.tick
      assert_equal [{:atom1=>"1"}, {:atom1=>"2"}], runner1.tables[:local2_at_p1].map{ |t| Hash[t.each_pair.to_a] }

      runner2.tick
      assert_equal [{:deleg_from_p1_2_1_x_0=>"1"}, {:deleg_from_p1_2_1_x_0=>"2"}],
        runner2.tables[:deleg_from_p1_2_1_at_p2].map{ |t| Hash[t.each_pair.to_a] }
      assert_equal [{:atom1=>"3"}], runner2.tables[:local1_at_p2].map{ |t| Hash[t.each_pair.to_a] }
      assert_equal [{:atom1=>"1",:atom2=>"3"},{:atom1=>"2",:atom2=>"3"}], runner2.tables[:delegated_join_at_p2].map{ |t| Hash[t.each_pair.to_a] }
      
      runner1.tick
      assert_equal [{:atom1=>"1",:atom2=>"3"},{:atom1=>"2",:atom2=>"3"}], runner1.tables[:local3_at_p1].map{ |t| Hash[t.each_pair.to_a] }
      assert_equal [{:atom1=>"1",:atom2=>"3"},{:atom1=>"2",:atom2=>"3"}], runner2.tables[:delegated_join_at_p2].map{ |t| Hash[t.each_pair.to_a] }
    ensure
      File.delete(@pg_file1) if File.exists?(@pg_file1)
      File.delete(@pg_file2) if File.exists?(@pg_file2)
      if EventMachine::reactor_running?
        runner1.stop
        runner2.stop true
      end
    end
  end
end
