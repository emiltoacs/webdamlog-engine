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
fact r1@p1(1);
fact r1@p1(2);
rule r1@p2($x) :- r1@p1($x);
    EOF
    @pg_file1 = "TcSbufferDifferential_1"
    @username1 = "p1"
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
  
  def test_sbuffer_content
    runner1 = nil
    assert_nothing_raised do
      runner1 = WLRunner.create(@username1, @pg_file1, @port1, {wl_test: true})
    end    
    runner1.tick
    #    assert_equal(
    #      [["localhost:10001",
    #          ["p1",
    #            "0",
    #            {:facts=>{"r1_at_p2"=>[["1"], ["2"]]},
    #              :rules=>[],
    #              :declarations=>[],
    #              :facts_to_delete=>{}}]]],
    #      runner1.test_send_on_chan)
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


class TcHashDeepDiffTool < Test::Unit::TestCase
  include MixinTcWlTest
  
  def assert_deep_diff(diff, a, b)
    assert_equal(diff, a.deep_diff(b))
  end
  
  def test_no_difference
    assert_deep_diff(
      {},
      {"one" => 1, "two" => 2},
      {"two" => 2, "one" => 1}
    )
  end
 
  def test_fully_different
    assert_deep_diff(
      {"one" => [1, nil], "two" => [nil, 2]},
      {"one" => 1},
      {"two" => 2}
    )
  end
 
  def test_simple_difference
    assert_deep_diff(
      {"one" => [1, "1"]},
      {"one" => 1},
      {"one" => "1"}
    )
  end
 
  def test_complex_difference
    assert_deep_diff(
      {
        "diff" => ["a", "b"],
        "only a" => ["a", nil],
        "only b" => [nil, "b"],
        "nested" => {
          "y" => {
            "diff" => ["a", "b"]
          }
        }
 
      },
 
      {
        "one" => "1",
        "diff" => "a",
        "only a" => "a",
        "nested" => {
          "x" => "x",
          "y" => {
            "a" => "a",
            "diff" => "a"
          }
        }
      },
 
      {
        "one" => "1",
        "diff" => "b",
        "only b" => "b",
        "nested" => {
          "x" => "x",
          "y" => {
            "a" => "a",
            "diff" => "b"
          }
        }
      }
 
    )
  end
 
  def test_default_value
    assert_deep_diff(
      {"one" => [1, "default"]},
      {"one" => 1},
      Hash.new("default")
    )
  end
end

class TcHashDeepDiffSplitTool < Test::Unit::TestCase
  include MixinTcWlTest
  
  def assert_deep_diff(diff, a, b)
    assert_equal(diff, a.deep_diff_split(b))
  end
  
  def test_no_difference
    assert_deep_diff(
      [{},{}],
      {"one" => 1, "two" => 2},
      {"two" => 2, "one" => 1}
    )
  end
  
  def test_fully_different
    assert_deep_diff(
      [{"one"=>[1]}, {"two"=>[2]}],
      {"one" => 1},
      {"two" => 2}
    )
  end
  
  def test_simple_difference
    assert_deep_diff(
      [{"one"=>[1]}, {"one"=>["1"]}],
      {"one" => 1},
      {"one" => "1"}
    )
  end
 
  def test_complex_difference
    assert_deep_diff(
      [{"diff"=>["a"], "only a"=>["a"], "nested"=>{"y"=>{"diff"=>["a"]}}},
        {"diff"=>["b"], "nested"=>{"y"=>{"diff"=>["b"]}}, "only b"=>["b"]}], 
      {
        "one" => "1",
        "diff" => "a",
        "only a" => "a",
        "nested" => {
          "x" => "x",
          "y" => {
            "a" => "a",
            "diff" => "a"
          }
        }
      },
 
      {
        "one" => "1",
        "diff" => "b",
        "only b" => "b",
        "nested" => {
          "x" => "x",
          "y" => {
            "a" => "a",
            "diff" => "b"
          }
        }
      }
 
    )
  end
 
  def test_default_value
    assert_deep_diff(
      [{"one"=>[1]},{"one"=>["default"]}],
      {"one" => 1},
      Hash.new("default")
    )
  end  
end

class TcHashDeepDiffSplitLookupTool < Test::Unit::TestCase
  include MixinTcWlTest
  
  def assert_deep_diff(diff, a, b)
    assert_equal(diff, WLTools::deep_diff_split_lookup(a, b))
  end
  
  def test_no_difference
    assert_deep_diff(
      [{}, {}],      
      {"peer1"=> {
          "rel1" => [["fact1"],["fact2"],["fact3"]].to_set ,
          "rel2" => [["fact1", "fact12"],["fact2", "fact22"],["fact3", "fact32"]].to_set }
      },
      
      {"peer1"=> {
          "rel1" => [["fact1"],["fact2"],["fact3"]],
          "rel2" => [["fact1", "fact12"],["fact2", "fact22"],["fact3", "fact32"]]}
      }
    )
  end
 
  def test_fully_different
    assert_deep_diff(
      [{"peer1"=> {
            "rel1" => [["fact1"],["fact2"],["fact3"]] ,
            "rel2" => [["fact1", "fact12"],["fact2", "fact22"],["fact3", "fact32"]] }
        },      
        {"peer2"=> {
            "rel3" => [["fact4"],["fact5"],["fact6"]],
            "rel4" => [["fact14", "fact125"],["fact24", "fact225"],["fact34", "fact325"]]}
        }],
      
      {"peer1"=> {
          "rel1" => [["fact1"],["fact2"],["fact3"]].to_set ,
          "rel2" => [["fact1", "fact12"],["fact2", "fact22"],["fact3", "fact32"]].to_set }
      },
      
      {"peer2"=> {
          "rel3" => [["fact4"],["fact5"],["fact6"]],
          "rel4" => [["fact14", "fact125"],["fact24", "fact225"],["fact34", "fact325"]]}
      }
    )
  end
  
  def test_simple_difference
    assert_deep_diff(
      [{"peer1"=>
            {"rel1"=>[["fact3"]], "rel2"=>[["fact2", "fact22"], ["fact3", "fact32"]]}},
        {"peer1"=>
            {"rel1"=>[["fact6"]],
            "rel2"=>[["fact24", "fact22"], ["fact3", "fact325"]]}}],
      
      {"peer1"=> {
          "rel1" => [["fact1"],["fact2"],["fact3"]].to_set ,
          "rel2" => [["fact1", "fact12"],["fact2", "fact22"],["fact3", "fact32"]].to_set }
      },
      
      {"peer1"=> {
          "rel1" => [["fact1"],["fact2"],["fact6"]],
          "rel2" => [["fact1", "fact12"],["fact24", "fact22"],["fact3", "fact325"]]}
      }
    )
  end
  
  def test_complex_difference
    assert_deep_diff(
      [{ "peer1"=>
            {"rel1"=>[["fact3"]], "rel2"=>[["fact2", "fact22"], ["fact3", "fact32"]]},
          "peer2"=>
            {"rel1"=>[["fact6"]],
            "rel2"=>
              [["fact1", "fact12"], ["fact24", "fact22"], ["fact3", "fact325"]]}},
        { "peer1"=>
            {"rel1"=>[["fact6"]], "rel2"=>[["fact24", "fact22"], ["fact3", "fact325"]]},
          "peer3"=>
            {"rel1"=>[["fact1"], ["fact2"], ["fact3"]],
            "rel2"=>
              [["fact211", "fact212"],
              ["fact222", "fact223"],
              ["fact331", "fact332"]]}}],
      
      { "peer1"=> {
          "rel1" => [["fact1"],["fact2"],["fact3"]].to_set ,
          "rel2" => [["fact1", "fact12"],["fact2", "fact22"],["fact3", "fact32"]].to_set },
        "peer2"=> {
          "rel1" => [["fact6"]],
          "rel2" => [["fact1", "fact12"],["fact24", "fact22"],["fact3", "fact325"]]}
      },
      
      { "peer1"=> {
          "rel1" => [["fact1"],["fact2"],["fact6"]],
          "rel2" => [["fact1", "fact12"],["fact24", "fact22"],["fact3", "fact325"]]},
        "peer3"=> {
          "rel1" => [["fact1"],["fact2"],["fact3"]],
          "rel2" => [["fact211", "fact212"],["fact222", "fact223"],["fact331", "fact332"]]}
      }
    )
  end
end

class TcHashInternalToSet < Test::Unit::TestCase
  include MixinTcWlTest
  
  def test_to_set
    assert_equal(
      {"peer1"=> {
          "rel1" => [["fact1"],["fact2"],["fact3"]].to_set ,
          "rel2" => [["fact1", "fact12"],["fact2", "fact22"],["fact3", "fact32"]].to_set }
      },
      WLTools::transform_first_inner_array_into_set( 
        {"peer1" => {
            "rel1" => [["fact1"],["fact2"],["fact3"]],
            "rel2" => [["fact1", "fact12"],["fact2", "fact22"],["fact3", "fact32"]] }
        }
      )
    )
  end
end