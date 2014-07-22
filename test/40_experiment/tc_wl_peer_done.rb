$:.unshift File.dirname(__FILE__)
require_relative '../header_test'
require_relative '../../lib/webdamlog_runner'

require 'test/unit'

class TcWlPeerDoneRunFg < Test::Unit::TestCase
  include MixinTcWlTest

  def setup
    @pg1 = <<-EOF
peer testsf = localhost:10000;
collection ext per photos@testsf(photo*,owner*);
collection ext per tags@testsf(img*,tag*);
collection ext per album@testsf(pict*,owner*);
collection ext per peer_done@testsf(key*);
fact photos@testsf(1,"alice");
fact photos@testsf(2,"alice");
fact photos@testsf(3,"alice");
fact photos@testsf(4,"alice");
fact photos@testsf(5,"alice");
fact photos@testsf(6,"bob");
fact tags@testsf(1,"alice");
fact tags@testsf(1,"bob");
fact tags@testsf(2,"alice");
fact tags@testsf(3,"bob");
fact tags@testsf(4,"charlie");
fact tags@testsf(5,"alice");
fact tags@testsf(5,"charlie");
fact tags@testsf(6,"alice");
fact tags@testsf(6,"bob");
fact tags@testsf(6,"charlie");
rule album@testsf($img,$owner) :- photos@testsf($img,$owner), tags@testsf($img,"alice"), tags@testsf($img,"bob");
    EOF
    @pg_file1 = "test_peer_done_1"
    @username1 = "testsf"
    @port1 = "10000"
    # create program files
    File.open(@pg_file1,"w"){ |file| file.write @pg1 }
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
  end

  # test that run_fg blocks until the peers properly dies
  def test_peer_done_run_fg_blocking
    runner1 = WLRunner.create(@username1, @pg_file1, @port1, {:dies_at_tick => 1})
    assert_equal 1, runner1.instance_variable_get(:@dies_at_tick)
    runner1.run_fg
    assert_equal 2, runner1.budtime
  end  
end


class TcWlTestPeersSendPeerDoneMessage < Test::Unit::TestCase
  include MixinTcWlTest

  def setup
    @pg1 = <<-EOF
peer testsf = localhost:10000;
peer test2 = localhost:10001;
collection ext per photos@testsf(photo*,owner*);
collection ext per tags@testsf(img*,tag*);
collection ext per album@testsf(pict*,owner*);
collection int peer_done@testsf(key*);
fact photos@testsf(1,"alice");
fact photos@testsf(2,"alice");
fact photos@testsf(3,"alice");
fact photos@testsf(4,"alice");
fact photos@testsf(5,"alice");
fact photos@testsf(6,"bob");
fact tags@testsf(1,"alice");
fact tags@testsf(1,"bob");
fact tags@testsf(2,"alice");
fact tags@testsf(3,"bob");
fact tags@testsf(4,"charlie");
fact tags@testsf(5,"alice");
fact tags@testsf(5,"charlie");
fact tags@testsf(6,"alice");
fact tags@testsf(6,"bob");
fact tags@testsf(6,"charlie");
rule album@testsf($img,$owner) :- photos@testsf($img,$owner), tags@testsf($img,"alice"), tags@testsf($img,"bob");
rule peer_done@test2($t) :- peer_done@testsf($t);

    EOF
    @pg_file1 = "test_peer_done_1"
    @username1 = "testsf"
    @port1 = "10000"
    # create program files
    File.open(@pg_file1,"w"){ |file| file.write @pg1 }

    @pg2 = <<-EOF
peer testsf = localhost:10000;
peer test2 = localhost:10001;
collection ext per photos@test2(photo*,owner*);
collection ext per tags@test2(img*,tag*);
collection ext per album@test2(pict*,owner*);
collection int peer_done@test2(key*);
fact friend@test2(test1,"picture");
fact friend@test2(test2,"picture");
fact photos@test2(1,"test2");
fact photos@test2(2,"test2");
fact photos@test2(4,"test2");
fact tags@test2(1,"bob");
fact tags@test2(3,"bob");
fact tags@test2(4,"alice");
fact tags@test2(4,"bob");
    EOF
    @pg_file2 = "test_peer_done_2"
    @username2 = "test2"
    @port2 = "10001"
    # create program files
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

  # test that peer_done propagates correctly
  def test_peers_send_peer_done_message
    runner1 = WLRunner.create(@username1, @pg_file1, @port1, {:dies_at_tick => 1})
    runner2 = WLRunner.create(@username2, @pg_file2, @port2)

    runner2.run_bg_no_tick
    runner1.run_fg
    
    assert_equal 1, runner1.instance_variable_get(:@dies_at_tick)
    assert_equal 0, runner2.instance_variable_get(:@dies_at_tick)
    assert_equal 2, runner1.budtime
    assert_equal 0, runner2.budtime

    assert_equal 1, runner1.tables[:peer_done_at_testsf].length
    assert_equal false, runner1.instance_variable_get(:@bud_started)
    assert_equal false, runner1.running_async
    #    assert_equal 1, runner2.tables[:peer_done_at_test2].length
    #    assert_equal false, runner2.instance_variable_get(:@bud_started)
    #    assert_equal false, runner2.running_async
  end
end