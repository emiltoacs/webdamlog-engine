$:.unshift File.dirname(__FILE__)
require_relative '../header_test'
require_relative '../../lib/webdamlog_runner'

require 'test/unit'

class TcWlSimpleDeletionWithoutPropagation < Test::Unit::TestCase
  include MixinTcWlTest

  def setup
    @pg1 = <<-EOF
peer test1 = localhost:10000;
collection ext per images@test1(photo*,owner*);
collection ext per photos@test1(photo*,owner*);
collection ext per tags@test1(img*,tag*);
collection ext per album@test1(pict*,owner*);
fact photos@test1(1,"test1");
fact photos@test1(2,"test1");
fact photos@test1(3,"test2");
fact images@test1(4,"test2");
fact images@test1(5,"test2");
fact images@test1(6,"test2");
fact tags@test1(1,"alice");
fact tags@test1(1,"bob");
fact tags@test1(5,"alice");
fact tags@test1(5,"alice");
rule album@test1($photo,$owner) :- images@test1($photo,$owner), tags@test1($photo,"alice");
    EOF
    @pg_file1 = "test_deletion_without_propagation_in_provenance_mode"
    @username1 = "test1"
    @port1 = "10000"
    # create program files
    File.open(@pg_file1,"w"){|file| file.write @pg1 }
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

  def test_deletion_without_propagation_in_provenance_mode
    runner1 = WLRunner.create(@username1, @pg_file1, @port1)
    # Check initial state
    runner1.tick
    assert_equal 1, runner1.budtime
    assert_equal [["1", "test1"], ["2", "test1"], ["3", "test2"]], runner1.tables[:photos_at_test1].pro{|t| t.to_a }.sort
    assert_equal [["1", "alice"], ["1", "bob"], ["5", "alice"]], runner1.tables[:tags_at_test1].pro{|t| t.to_a }.sort
    # Check that delete_facts does not trigger a new tick
    valid, err = runner1.delete_facts({"photos_at_test1"=>[["1", "test1"], ["2", "test1"]]})
    assert_equal({}, err)
    assert_equal({"photos_at_test1" => [["1", "test1"], ["2", "test1"]]}, valid)
    assert_equal 1, runner1.budtime
    assert_equal [["3", "test2"]], runner1.tables[:photos_at_test1].pro{|t| t.to_a }.sort
    assert_equal [["1", "alice"], ["1", "bob"], ["5", "alice"]], runner1.tables[:tags_at_test1].pro{|t| t.to_a }.sort
    # Check that fixpoint is reached even after deletion
    runner1.tick
    assert_equal 2, runner1.budtime
    assert_equal [["3", "test2"]], runner1.tables[:photos_at_test1].pro{|t| t.to_a }.sort
    assert_equal [["1", "alice"], ["1", "bob"], ["5", "alice"]], runner1.tables[:tags_at_test1].pro{|t| t.to_a }.sort
    # Check for further deletion
    valid, err = runner1.delete_facts({"tags_at_test1"=>[["1", "alice"], ["1", "bob"], ["5", "alice"]]})
    assert_equal({}, err)
    assert_equal 2, runner1.budtime
    assert_equal [["3", "test2"]], runner1.tables[:photos_at_test1].pro{|t| t.to_a }.sort
    assert_equal [], runner1.tables[:tags_at_test1].pro{|t| t.to_a }.sort
  end
end



class TcWlSimpleDeletionWithSimplePropagation < Test::Unit::TestCase
  include MixinTcWlTest

  def setup
    @pg1 = <<-EOF
peer test1 = localhost:10000;
collection ext per images@test1(photo*,owner*);
collection ext per photos@test1(photo*,owner*);
collection ext per tags@test1(img*,tag*);
collection ext per album@test1(pict*,owner*);
fact photos@test1(1,"test1");
fact photos@test1(2,"test1");
fact photos@test1(3,"test2");
fact images@test1(4,"test2");
fact images@test1(5,"test2");
fact images@test1(6,"test2");
fact tags@test1(1,"alice");
fact tags@test1(1,"bob");
fact tags@test1(5,"alice");
fact tags@test1(5,"alice");
rule album@test1($photo,$owner) :- photos@test1($photo,$owner);
rule album@test1($photo,$owner) :- images@test1($photo,$owner), tags@test1(@photo,"alice");
    EOF
    @pg_file1 = "test_deletion_with_simple_propagation"
    @username1 = "test1"
    @port1 = "10000"
    # create program files
    File.open(@pg_file1,"w"){|file| file.write @pg1 }
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

  def test_deletion_with_simple_propagation

  end

end