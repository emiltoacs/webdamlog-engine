$:.unshift File.dirname(__FILE__)
require_relative '../header_test'
require_relative '../../lib/webdamlog_runner'

require 'test/unit'

class TcSbufferDifferential < Test::Unit::TestCase
  include MixinTcWlTest

  def setup
    @pg1 = <<-EOF
peer p1 = localhost:10000;
peer p2 = localhost:10001;
collection ext per r1@p1(atom1*);
collection int r2@p1(atom1*);
fact r1@p1(6,"bob");
fact r1@p1(6,"charlie");
rule r1@p2($x) :- r1@p1($x);
    EOF
    @pg_file1 = "TcSbufferDifferential_1"
    @username1 = "testsf"
    @port1 = "10000"
    File.open(@pg_file1,"w"){ |file| file.write @pg1 }
    
    @pg2 = <<-EOF
peer p1 = localhost:10000;
peer p2 = localhost:11111;
collection ext per r1@p2(atom1*);
collection int r2@p2(atom1*);
fact r1@p2(3);
fact r1@p2(4);
rule r2@p1($x) :- r1@p2($x);
end
    EOF
    @username2 = "p2"
    @port2 = "10001"
    @pg_file2 = "TcSbufferDifferential_2"
    File.open(@pg_file2,"w"){ |file| file.write @pg2 }
  end

  def teardown
    # delete all Webdamlog runners
    ObjectSpace.each_object(WLRunner) do |obj|
      rule_dir = obj.rule_dir
      obj.delete
      clean_rule_dir rule_dir
    end
    if EventMachine::reactor_running?
      Bud::stop_em_loop
      EventMachine::reactor_thread.join
    end
    ObjectSpace.garbage_collect
    File.delete(@pg_file1) if File.exists?(@pg_file1)
    File.delete(@pg_file2) if File.exists?(@pg_file2)
  end
  
  def test_sbuffer_differential_merge
    runner1 = nil
    runner2 = nil
    assert_nothing_raised do
      runner1 = WLRunner.create(@username1, @pg_file1, @port1)
      runner2 = WLRunner.create(@username2, @pg_file2, @port2)
    end
    
    
    
  end
  
end
