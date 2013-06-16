$:.unshift File.dirname(__FILE__)
require 'header_test'
require_relative '../lib/webdamlog_runner'

require 'test/unit'

# test create and run in {WLRunner} with :delay_fact_loading options true
class TcWlWlbudDelayLoadFact < Test::Unit::TestCase
  include MixinTcWlTest

  def setup
    @pg = <<-EOF
peer p1=localhost:11111;
peer p2=localhost:11112;
peer p3=localhost:11113;
collection ext persistent local@local(atom1*);
collection ext per join_delegated@local(atom1*);
collection int local2@local(atom1*);
fact local@local(1);
fact local@local(2);
fact local@local(3);
fact local@local(4);
rule join_delegated@p0($x):- local@local($x),delegated@p1($x),delegated@p2($x),delegated@p3($x);
rule local2@local($x) :- local@local($x);
end
    EOF
    @username = "test_delay_fact_loading"
    @port = "11110"
    @pg_file = "test_delay_fact_loading_program"
    File.open(@pg_file,"w"){ |file| file.write @pg }
  end

  def teardown
    ObjectSpace.each_object(WLRunner){ |obj| obj.delete }
    ObjectSpace.garbage_collect
  end

  def test_delay_fact_loading
    wl_obj = nil
    assert_nothing_raised do
      wl_obj = WLRunner.create(@username, @pg_file, @port, {:delay_fact_loading => true})
    end
    # check everything is loaded but the facts
    assert_equal({"test_delay_fact_loading"=>"127.0.0.1:11110",
        "p1"=>"localhost:11111",
        "p2"=>"localhost:11112",
        "p3"=>"localhost:11113"},
      wl_obj.wl_program.wlpeers)
    assert_equal(["local_at_test_delay_fact_loading",
        "join_delegated_at_test_delay_fact_loading",
        "local2_at_test_delay_fact_loading",
        "deleg_from_test_delay_fact_loading_1_1_at_p1"],
      wl_obj.wl_program.wlcollections.keys)
    assert_equal [:localtick,
      :stdio,
      :halt,
      :periodics_tbl,
      :t_cycle,
      :t_depends,
      :t_provides,
      :t_rules,
      :t_stratum,
      :t_table_info,
      :t_table_schema,
      :t_underspecified,
      :t_derivation,
      :chan,
      :sbuffer,
      :local_at_test_delay_fact_loading,
      :join_delegated_at_test_delay_fact_loading,
      :local2_at_test_delay_fact_loading,
      :deleg_from_test_delay_fact_loading_1_1_at_p1], wl_obj.tables.values.map { |coll| coll.tabname }
    assert_equal [], wl_obj.tables[:local_at_test_delay_fact_loading].to_a.sort
    assert_equal [], wl_obj.tables[:join_delegated_at_test_delay_fact_loading].to_a.sort
    assert_equal [], wl_obj.tables[:local2_at_test_delay_fact_loading].to_a.sort
    assert_equal [], wl_obj.tables[:deleg_from_test_delay_fact_loading_1_1_at_p1].to_a.sort
    assert_equal ["rule join_delegated_at_p0($x) :- local_at_test_delay_fact_loading($x), delegated_at_p1($x), delegated_at_p2($x), delegated_at_p3($x);",
      "rule local2_at_test_delay_fact_loading($x) :- local_at_test_delay_fact_loading($x);",
      "rule deleg_from_test_delay_fact_loading_1_1_at_p1($x) :- local_at_test_delay_fact_loading($x);",
      "rule join_delegated@p0($x):-deleg_from_test_delay_fact_loading_1_1@p1($x),delegated@p1($x),delegated@p2($x),delegated@p3($x);"],
      wl_obj.wl_program.rule_mapping.values.map{ |rules| rules.first.is_a?(WLBud::WLRule) ? rules.first.show_wdl_format : rules.first }

    # Run engine as usual except that it has not facts inserted
    assert_nothing_raised do
      wl_obj.run_engine
    end
    assert_equal [], wl_obj.tables[:local_at_test_delay_fact_loading].to_a.sort
    assert_equal [], wl_obj.tables[:join_delegated_at_test_delay_fact_loading].to_a.sort
    assert_equal [], wl_obj.tables[:local2_at_test_delay_fact_loading].to_a.sort
    assert_equal [], wl_obj.tables[:deleg_from_test_delay_fact_loading_1_1_at_p1].to_a.sort

    # TODO check fact has been added and rules evaluated
    wl_obj.load_bootstrap_fact
    assert_equal [["1"], ["2"], ["3"], ["4"]], 
      wl_obj.tables[:local_at_test_delay_fact_loading].to_a.sort.map { |t| t.to_a },
      "some facts should have been added directly by load_bootstrap_fact"
    assert_equal [], wl_obj.tables[:join_delegated_at_test_delay_fact_loading].to_a.sort.map { |t| t.to_a }
    assert_equal [["1"], ["2"], ["3"], ["4"]], 
      wl_obj.tables[:local2_at_test_delay_fact_loading].to_a.sort.map { |t| t.to_a },
      "some facts should have been derived beause of adding by load_bootstrap_fact"
    assert_equal [], wl_obj.tables[:deleg_from_test_delay_fact_loading_1_1_at_p1].to_a.sort.map { |t| t.to_a }    
  end
  
end
