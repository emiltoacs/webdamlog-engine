$:.unshift File.dirname(__FILE__)
require_relative '../header_test'
require_relative '../../lib/webdamlog_runner'

require 'test/unit'


class TcWlTracePushOut < Test::Unit::TestCase
  include MixinTcWlTest

  def setup
    @pg = <<-EOF
peer testsf = localhost:10000;
collection ext per photos@testsf(photo*,owner*);
collection ext per images@testsf(photo*,owner*,useless*);
collection ext per tags@testsf(img*,tag*);
collection ext per album@testsf(pict*,owner*);
fact photos@testsf(1,"alice");
fact photos@testsf(2,"alice");
fact photos@testsf(3,"alice");
fact tags@testsf(1,"alice");
fact tags@testsf(1,"bob");
fact tags@testsf(2,"alice");
fact tags@testsf(3,"bob");
fact tags@testsf(5,"alice");
fact tags@testsf(5,"bob");
fact images@testsf(4,"bob","uselessfield");
fact images@testsf(5,"bob","uselessfield");
rule album@testsf($img,$owner) :- photos@testsf($img,$owner), tags@testsf($img,"alice"), tags@testsf($img,"bob");
rule photos@testsf($X,$Y):-images@testsf($X,$Y,$Z);
    EOF
    @pg_file = "test_do_wiring"
    @username = "testsf"
    @port = "10000"
    # create program files
    File.open(@pg_file,"w"){ |file| file.write @pg }
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
    File.delete(@pg_file) if File.exists?(@pg_file)
  end

  
  def test_build_proof_when_push_out
    runner = WLRunner.create(@username, @pg_file, @port)
    runner.tick
    bud_rules = []
    Dir.chdir(runner.rule_dir) do
      wlrule_files = Dir.glob("webdamlog*")
      assert_equal 2, wlrule_files.length
      wlrule_files.each do |file| File.open(file) do |io|
          io.readlines.each do |line|
            bud_rules << line.strip if line.include? "photos_at_testsf"
          end
        end
      end
    end
    # Check that we translated the rule as expected
    assert_equal [
      "album_at_testsf <= (photos_at_testsf * tags_at_testsf * tags_at_testsf ).combos(photos_at_testsf.photo => tags_at_testsf.img,photos_at_testsf.photo => tags_at_testsf.img) do |atom0, atom1, atom2| [atom0[0], atom0[1]] if atom1[1]=='alice' and atom2[1]=='bob' and atom1[0]==atom2[0] end;",
      "photos_at_testsf <= images_at_testsf do |atom0| [atom0[0], atom0[1]] end;"],
      bud_rules

    # Check the traces in the provenance graph
    assert_equal([["photos_at_testsf",
          "tags_at_testsf",
          "(photos_at_testsf*tags_at_testsf)",
          "(photos_at_testsf*tags_at_testsf*tags_at_testsf)"],
        ["images_at_testsf", "project[:photo, :owner, :useless]"]],
      runner.provenance_graph.traces.values.map{|rtrace| rtrace.print_push_elems})

    assert_equal(
      [[0,
          [{[["1", "alice"], ["1", "alice"], ["1", "bob"]]=>["1", "alice"]},
            {[["5", "bob"], ["5", "alice"], ["5", "bob"]]=>["5", "bob"]}]],
        [1,
          [{["4", "bob", "uselessfield"]=>["4", "bob"]},
            {["5", "bob", "uselessfield"]=>["5", "bob"]}]]],
      runner.provenance_graph.traces.map do |rid,rtrace|
        [rid,rtrace.pushed_out_facts.map{|ptree| ptree.to_a_budstruct}]
      end)

    assert_equal ["(photos_at_testsf*tags_at_testsf*tags_at_testsf)",
      "project[photo, owner, useless]"],
      runner.provenance_graph.traces.map{|rid,rtrace| rtrace.print_last_push_elem }
    
  end
end



# Check that all the push-joins are created from one rules, there is no reuse of
# the same joins. That is if the same join appear in two different rule, two
# different pushshjoins will be created.
class TcWlTracePushSHJoin< Test::Unit::TestCase
  include MixinTcWlTest

  def setup
    @pg = <<-EOF
peer testsf = localhost:10000;
collection ext per photos@testsf(photo*,owner*);
collection ext per images@testsf(photo*,owner*,useless*);
collection ext per tags@testsf(img*,tag*);
collection ext per album1@testsf(pict*,owner*);
collection ext per album2@testsf(pict*,owner*);
collection ext per album3@testsf(pict*,owner*);
fact photos@testsf(1,"alice");
fact photos@testsf(2,"alice");
fact photos@testsf(3,"alice");
fact tags@testsf(1,"alice");
fact tags@testsf(1,"bob");
fact tags@testsf(2,"alice");
fact tags@testsf(3,"bob");
fact tags@testsf(5,"alice");
fact tags@testsf(5,"bob");
fact images@testsf(4,"bob","uselessfield");
fact images@testsf(5,"bob","uselessfield");
rule album1@testsf($img,$owner) :- photos@testsf($img,$owner), tags@testsf($img,"alice"), tags@testsf($img,"bob");
rule album2@testsf($img,$owner) :- photos@testsf($img,$owner), tags@testsf($img,"alice");
rule album3@testsf($img,$owner) :- photos@testsf($img,$owner), tags@testsf($img,"alice");
    EOF
    @pg_file = "test_do_wiring"
    @username = "testsf"
    @port = "10000"
    # create program files
    File.open(@pg_file,"w"){ |file| file.write @pg }
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
    File.delete(@pg_file) if File.exists?(@pg_file)
  end

  # Test that push_joins are not reused across rules
  def test_pushshjoin_shred_rules
    runner = WLRunner.create(@username, @pg_file, @port)
    runner.tick
    bud_rule = []
    Dir.chdir(runner.rule_dir) do
      wlrule_files = Dir.glob("webdamlog*")
      assert_equal 3, wlrule_files.length
      wlrule_files.each do |file| File.open(file) do |io|
          io.readlines.each do |line|
            bud_rule << line.strip if line.include? "album1_at_testsf" or line.include? "album2_at_testsf" or line.include? "album3_at_testsf"
          end
        end
      end
    end
    assert_equal ["album1_at_testsf <= (photos_at_testsf * tags_at_testsf * tags_at_testsf ).combos(photos_at_testsf.photo => tags_at_testsf.img,photos_at_testsf.photo => tags_at_testsf.img) do |atom0, atom1, atom2| [atom0[0], atom0[1]] if atom1[1]=='alice' and atom2[1]=='bob' and atom1[0]==atom2[0] end;",
      "album2_at_testsf <= (photos_at_testsf * tags_at_testsf ).combos(photos_at_testsf.photo => tags_at_testsf.img) do |atom0, atom1| [atom0[0], atom0[1]] if atom1[1]=='alice' end;",
      "album3_at_testsf <= (photos_at_testsf * tags_at_testsf ).combos(photos_at_testsf.photo => tags_at_testsf.img) do |atom0, atom1| [atom0[0], atom0[1]] if atom1[1]=='alice' end;"],
      bud_rule

    assert_equal(["photos_at_testsf",
        "tags_at_testsf",
        "(photos_at_testsf*tags_at_testsf)",
        "(photos_at_testsf*tags_at_testsf*tags_at_testsf)",
        "(photos_at_testsf*tags_at_testsf)",
        "(photos_at_testsf*tags_at_testsf)"],
      runner.provenance_graph.traces.values.map{|rtrace| rtrace.push_elems}.flatten.map{|push_elem| WLBud::RuleTrace.sanitize_push_elem_name(push_elem)} )

    assert_equal([],
      runner.provenance_graph.traces.values.map{|rtrace| rtrace.push_elems}.flatten.map{|push_elem| push_elem.object_id}.dups )
  end
end



# Simple test mostly used during development. It has only one rule
class TcWlTraceDoWiring < Test::Unit::TestCase
  include MixinTcWlTest
  
  def setup
    @pg = <<-EOF
peer testsf = localhost:10000;
collection ext per photos@testsf(photo*,owner*);
collection ext per tags@testsf(img*,tag*);
collection ext per album@testsf(pict*,owner*);
fact photos@testsf(1,"alice");
fact photos@testsf(2,"alice");
fact photos@testsf(3,"alice");
fact tags@testsf(1,"alice");
fact tags@testsf(1,"bob");
fact tags@testsf(2,"alice");
fact tags@testsf(3,"bob");
rule album@testsf($img,$owner) :- photos@testsf($img,$owner), tags@testsf($img,"alice"), tags@testsf($img,"bob");
    EOF
    @pg_file = "test_do_wiring"
    @username = "testsf"
    @port = "10000"
    # create program files
    File.open(@pg_file,"w"){ |file| file.write @pg }
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
    File.delete(@pg_file) if File.exists?(@pg_file)
  end

  # Simple test with a single rule
  def test_trace_simple_derivation
    runner = WLRunner.create(@username, @pg_file, @port)
    runner.tick
    bud_rule = ""
    Dir.chdir(runner.rule_dir) do
      wlrule_files = Dir.glob("webdamlog*")
      assert_equal 1, wlrule_files.length
      File.open(wlrule_files.first) do |io|
        io.readlines.each do |line|
          bud_rule = line.strip if line.include? "album_at_testsf"
        end
      end
    end
    assert_equal "album_at_testsf <= (photos_at_testsf * tags_at_testsf * tags_at_testsf ).combos(photos_at_testsf.photo => tags_at_testsf.img,photos_at_testsf.photo => tags_at_testsf.img) do |atom0, atom1, atom2| [atom0[0], atom0[1]] if atom1[1]=='alice' and atom2[1]=='bob' and atom1[0]==atom2[0] end;",
      bud_rule

    assert_equal(2, runner.push_elems.size)

    # Test the content of push_elems, push_sorted_elems and scanners attributes
    # that stores elements for evaluation
    assert_equal([[:photos_at_testsf, :tags_at_testsf], [nil, :tags_at_testsf]],
      runner.push_elems.map { |struct,value| struct[2].map {|pshelt| pshelt.instance_variable_get(:@collection_name)}})
    assert_equal([[:join, Classwlengineoftestsfon10000, nil],
        [:join, Classwlengineoftestsfon10000, nil]],
      runner.push_elems.map { |struct,value| [struct[1],struct[3].class,struct[4]]})
    # @push_elems contains all the the non-collection push elements ie.
    # operations such as join implemented as PushSHJoin
    assert_equal(["(photos_at_testsf*tags_at_testsf)",
        "(photos_at_testsf*tags_at_testsf*tags_at_testsf)"],
      runner.push_elems.values.map { |pshelt| pshelt.tabname.to_s.gsub(/:[0-9]*/,'')})
    # @scanners contains all the the collection push elements ie. the
    # ScannersElement
    assert_equal([[:photos_at_testsf, :tags_at_testsf]],
      runner.scanners.map{|stratum| stratum.keys.map{|key| key[1]}})
    # @push_sorted_elems contains all the the PushElements order in a
    # breadth-first order
    assert_equal([["photos_at_testsf",
          "tags_at_testsf",
          "(photos_at_testsf*tags_at_testsf)",
          "(photos_at_testsf*tags_at_testsf*tags_at_testsf)"]],
      runner.instance_variable_get(:@push_sorted_elems).map{|stratum| stratum.map {|pshelt| pshelt.elem_name.to_s.gsub(/:[0-9]*/,'')}})
    # provenance-graph has received the right list of push elements
    assert_equal([["photos_at_testsf",
          "tags_at_testsf",
          "(photos_at_testsf*tags_at_testsf)",
          "(photos_at_testsf*tags_at_testsf*tags_at_testsf)"]],
      runner.provenance_graph.traces.values.map{|rtrace| rtrace.print_push_elems})
  end

end