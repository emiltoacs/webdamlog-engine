$:.unshift File.dirname(__FILE__)
require_relative '../header_test'
require_relative '../../lib/webdamlog_runner'

require 'test/unit'

class TcRunawayTest < Test::Unit::TestCase
  include MixinTcWlTest

  def setup
    @pg1 = <<-EOF
peer p1=localhost:11110;
peer p2=localhost:11111;
collection ext per r1@p1(atom1*);
collection int r2@p1(atom1*);
collection ext per r3@p1(atom1*);
fact r1@p1(1);
fact r1@p1(2);
fact r3@p1(3);
rule r5@p2($x) :- r2@p1($x),r3@p1($x);
end
    EOF
    @username1 = "p1"
    @port1 = "11110"
    @pg_file1 = "test_runaway1"
    File.open(@pg_file1,"w"){ |file| file.write @pg1 }

    @pg2 = <<-EOF
peer p2=localhost:11111;
peer p1=localhost:11110;
collection ext per r4@p2(atom1*);
collection int r5@p2(atom1*);
fact r4@p2(3);
fact r4@p2(4);
rule r2@p1($x) :- r4@p2($x);
end
    EOF
    @username2 = "p2"
    @port2 = "11111"
    @pg_file2 = "test_runaway2"
    File.open(@pg_file2,"w"){ |file| file.write @pg2 }
  end

  def teardown
    ObjectSpace.each_object(WLRunner){ |obj| obj.delete }
    ObjectSpace.garbage_collect
  end

  def test_message_clobber    
    runner1 = nil
    runner2 = nil
    assert_nothing_raised do
      runner1 = WLRunner.create(@username1, @pg_file1, @port1, {:accessc => false, :debug => false })
      runner2 = WLRunner.create(@username2, @pg_file2, @port2, {:accessc => false, :debug => false })
    end

    runner1.on_shutdown do
      assert_equal(
        [["1"], ["2"]],
        runner1.tables[:r1_at_p1].pro{|t| t.to_a }.sort)
      assert_equal(
        [["3"], ["4"]],
        runner1.tables[:r2_at_p1].pro{|t| t.to_a }.sort)
      assert_equal(
        [["3"]],
        runner1.tables[:r3_at_p1].pro{|t| t.to_a }.sort)
      assert_equal(2,runner1.budtime)
    end
    runner2.on_shutdown do
      assert_equal(
        [["3"], ["4"]],
        runner2.tables[:r4_at_p2].pro{|t| t.to_a }.sort)
      assert_equal(
        [["3"]],
        runner2.tables[:r5_at_p2].pro{|t| t.to_a }.sort)
      assert_equal(2,runner2.budtime)
    end

    runner1.run_engine
    runner2.run_engine
    sleep 3

  ensure      
    if EventMachine::reactor_running?
      runner1.stop
      runner2.stop
    end
    File.delete(@pg_file1) if File.exists?(@pg_file1)
    File.delete(@pg_file2) if File.exists?(@pg_file2)
  end
end
