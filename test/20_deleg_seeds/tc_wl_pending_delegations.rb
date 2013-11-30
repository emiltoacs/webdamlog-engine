$:.unshift File.dirname(__FILE__)
require_relative '../header_test'
require_relative '../../lib/webdamlog_runner'

require 'test/unit'

# Test pending delegations attribute when options[:filter_delegations]
class TcWl1PendingDelegations < Test::Unit::TestCase
  include MixinTcWlTest

  def setup
    @pg = <<-EOF
peer test_pending_delegation_content=localhost:11110;
peer p1=localhost:11111;
peer p2=localhost:11112;
peer p3=localhost:11113;
collection ext persistent local@test_pending_delegation_content(atom1*);
collection ext per join_delegated@test_pending_delegation_content(atom1*);
collection int local2@test_pending_delegation_content(atom1*);
fact local@test_pending_delegation_content(1);
fact local@test_pending_delegation_content(2);
fact local@test_pending_delegation_content(3);
fact local@test_pending_delegation_content(4);
rule local2@test_pending_delegation_content($x) :- local@test_pending_delegation_content($x);
end
    EOF
    @username = "test_pending_delegation_content"
    @port = "11110"
    @pg_file = "test_pending_delegation_content_program"
    File.open(@pg_file,"w"){ |file| file.write @pg }
  end

  def teardown
    File.delete(@pg_file) if File.exists?(@pg_file)
    ObjectSpace.each_object(WLRunner) do |obj|
      clean_rule_dir obj.rule_dir
      obj.delete
    end
    ObjectSpace.garbage_collect
  end

  # check that delegations are retained in pending_delegation and not installed
  def test_pending_delegation_content
    runner = nil
    assert_nothing_raised do
      runner = WLRunner.create(@username, @pg_file, @port, {filter_delegations: true})
    end
    assert runner.filter_delegations
    runner.run_engine
    runner.sync_do {
      runner.chan <~ [["localhost:11110",
          ["p0", "0",
            {"rules"=>["rule local2@test_pending_delegation_content('14') :- local@test_pending_delegation_content('4');"],
              "facts"=>{},
              "declarations"=>[]
            }]]]}
    runner.sync_do {
      runner.chan <~ [["localhost:11110",
          ["p0", "0",
            {"rules"=>["rule local2@test_pending_delegation_content('15') :- local@test_pending_delegation_content('4');"],
              "facts"=>{},
              "declarations"=>[]
            }]]]
    }
    # force another tick to flush chan
    runner.sync_do {  }
    # two pending delegations
    assert_equal({:p0=>
          {0=>
            [["rule local2@test_pending_delegation_content('14') :- local@test_pending_delegation_content('4');"],
            ["rule local2@test_pending_delegation_content('15') :- local@test_pending_delegation_content('4');"]]}},
      runner.pending_delegations)

    assert_equal(["rule local2@test_pending_delegation_content($x) :- local@test_pending_delegation_content($x);"],
      runner.wl_program.rule_mapping.values.map{ |ar| ar.first.show_wdl_format} )

    assert_equal({:p0=>
          {0=>
            [["rule local2@test_pending_delegation_content('14') :- local@test_pending_delegation_content('4');"],
            ["rule local2@test_pending_delegation_content('15') :- local@test_pending_delegation_content('4');"]]}},
      runner.flush_delegations)
    assert_equal({}, runner.pending_delegations)
  ensure
    runner.stop
    File.delete(@pg_file) if File.exists?(@pg_file)
  end
end
