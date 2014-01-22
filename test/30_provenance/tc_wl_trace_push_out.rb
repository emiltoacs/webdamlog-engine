$:.unshift File.dirname(__FILE__)
require_relative '../header_test'
require_relative '../../lib/webdamlog_runner'

require 'test/unit'

class TcWlTracePushOutWithSeed < Test::Unit::TestCase
  include MixinTcWlTest

  def setup
    @pg1 = <<-EOF
peer test1 = localhost:10000;
peer test2 = localhost:10001;
collection ext per friend@test1(friend*,fr_group*);
collection ext per photos@test1(photo*,owner*);
collection ext per tags@test1(img*,tag*);
collection ext per album@test1(pict*,owner*);
fact friend@test1(test1,"picture");
fact friend@test1(test2,"picture");
fact photos@test1(1,"test1");
fact photos@test1(2,"test1");
fact photos@test1(3,"test2");
fact tags@test1(1,"alice");
fact tags@test1(1,"bob");
fact tags@test1(2,"alice");
rule album@test1($photo,$owner) :- friend@test1($friend,"picture"), photos@$friend($photo,$owner), tags@$owner($photo,"bob");
    EOF
    @pg_file1 = "test_provenance_with_seeds_1"
    @username1 = "test1"
    @port1 = "10000"
    # create program files
    File.open(@pg_file1,"w"){ |file| file.write @pg1 }

    
    @pg2 = <<-EOF
peer test1 = localhost:10000;
peer test2 = localhost:10001;
collection ext per photos@test2(photo*,owner*);
collection ext per tags@test2(img*,tag*);
collection ext per album@test2(pict*,owner*);
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
    @pg_file2 = "test_provenance_with_seeds_2"
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

  def test_provenance_with_seeds
    runner1 = WLRunner.create(@username1, @pg_file1, @port1)
    runner2 = WLRunner.create(@username2, @pg_file2, @port2)

    runner1.tick
    runner2.tick

    # Check that we translated the rule as expected
    bud_rules_1 = []
    Dir.chdir(runner1.rule_dir) do
      wlrule_files = Dir.glob("webdamlog*")
      assert_equal 1, wlrule_files.length
      wlrule_files.each do |file| File.open(file) do |io|
          io.readlines.each do |line|
            bud_rules_1 << line.strip if line.include? "<="
          end
        end
      end
    end
    assert_equal [
      "seed_from_test1_1_1_at_test1 <= friend_at_test1 do |atom0| [atom0[0]] if atom0[1]=='picture' end;"],
      bud_rules_1
    bud_rules_2 = []
    Dir.chdir(runner2.rule_dir) do
      wlrule_files = Dir.glob("webdamlog*")
      assert_equal 0, wlrule_files.length
      wlrule_files.each do |file| File.open(file) do |io|
          io.readlines.each do |line|
            bud_rules_2 << line.strip if line.include? "<="
          end
        end
      end
    end
    assert_equal [], bud_rules_2

    runner1.tick
    runner2.tick

    # Check that we translated the rule as expected
    bud_rules_1 = []
    Dir.chdir(runner1.rule_dir) do
      wlrule_files = Dir.glob("webdamlog*")
      assert_equal 3, wlrule_files.length
      wlrule_files.each do |file| File.open(file) do |io|
          io.readlines.each do |line|
            bud_rules_1 << line.strip if line.include? "<="
          end
        end
      end
    end
    assert_equal [
      "seed_from_test1_3_1_at_test1 <= (seed_from_test1_1_1_at_test1 * photos_at_test1 ).combos() do |atom0, atom1| [atom1[0], atom1[1]] if atom0[0]=='test1' end;",
      "sbuffer <= seed_from_test1_1_1_at_test1 do |atom0| [\"localhost:10001\", \"deleg_from_test1_5_1_at_test2\", ['true']] if atom0[0]=='test2' end;",
      "seed_from_test1_1_1_at_test1 <= friend_at_test1 do |atom0| [atom0[0]] if atom0[1]=='picture' end;"],
      bud_rules_1    
    bud_rules_2 = []
    Dir.chdir(runner2.rule_dir) do
      wlrule_files = Dir.glob("webdamlog*")
      assert_equal 1, wlrule_files.length
      wlrule_files.each do |file| File.open(file) do |io|
          io.readlines.each do |line|
            bud_rules_2 << line.strip if line.include? "<=" or line.include? "<+"
          end
        end
      end
    end
    assert_equal [
      "seed_from_test2_1_1_at_test2 <= (deleg_from_test1_5_1_at_test2 * photos_at_test2 ).combos() do |atom0, atom1| [atom1[0], atom1[1]] if atom0[0]=='true' end;"],
      bud_rules_2

    runner1.tick
    runner2.tick

    # Check that we translated the rule as expected
    bud_rules_1 = []
    Dir.chdir(runner1.rule_dir) do
      wlrule_files = Dir.glob("webdamlog*")
      assert_equal 6, wlrule_files.length
      wlrule_files.each do |file| File.open(file) do |io|
          io.readlines.each do |line|
            bud_rules_1 << line.strip if line.include? "<="
          end
        end
      end
    end
    assert_equal ["seed_from_test1_3_1_at_test1 <= (seed_from_test1_1_1_at_test1 * photos_at_test1 ).combos() do |atom0, atom1| [atom1[0], atom1[1]] if atom0[0]=='test1' end;",
      "album_at_test1 <= (seed_from_test1_3_1_at_test1 * tags_at_test1 ).combos() do |atom0, atom1| ['2', 'test1'] if atom0[0]=='2' and atom1[0]=='2' and atom0[1]=='test1' and atom1[1]=='bob' end;",
      "album_at_test1 <= (seed_from_test1_3_1_at_test1 * tags_at_test1 ).combos() do |atom0, atom1| ['1', 'test1'] if atom0[0]=='1' and atom1[0]=='1' and atom0[1]=='test1' and atom1[1]=='bob' end;",
      "sbuffer <= seed_from_test1_1_1_at_test1 do |atom0| [\"localhost:10001\", \"deleg_from_test1_5_1_at_test2\", ['true']] if atom0[0]=='test2' end;",
      "seed_from_test1_1_1_at_test1 <= friend_at_test1 do |atom0| [atom0[0]] if atom0[1]=='picture' end;",
      "sbuffer <= seed_from_test1_3_1_at_test1 do |atom0| [\"localhost:10001\", \"deleg_from_test1_9_1_at_test2\", ['true']] if atom0[0]=='3' and atom0[1]=='test2' end;"],
      bud_rules_1
    bud_rules_2 = []
    Dir.chdir(runner2.rule_dir) do
      wlrule_files = Dir.glob("webdamlog*")
      assert_equal 5, wlrule_files.length
      wlrule_files.each do |file| File.open(file) do |io|
          io.readlines.each do |line|
            bud_rules_2 << line.strip if line.include? "<=" or line.include? "<+"
          end
        end
      end
    end
    assert_equal ["sbuffer <= (seed_from_test2_1_1_at_test2 * tags_at_test2 ).combos() do |atom0, atom1| [\"localhost:10000\", \"album_at_test1\", ['2', 'test2']] if atom0[0]=='2' and atom1[0]=='2' and atom0[1]=='test2' and atom1[1]=='bob' end;",
      "sbuffer <= (deleg_from_test1_9_1_at_test2 * tags_at_test2 ).combos() do |atom0, atom1| [\"localhost:10000\", \"album_at_test1\", ['3', 'test2']] if atom0[0]=='true' and atom1[0]=='3' and atom1[1]=='bob' end;",
      "seed_from_test2_1_1_at_test2 <= (deleg_from_test1_5_1_at_test2 * photos_at_test2 ).combos() do |atom0, atom1| [atom1[0], atom1[1]] if atom0[0]=='true' end;",
      "sbuffer <= (seed_from_test2_1_1_at_test2 * tags_at_test2 ).combos() do |atom0, atom1| [\"localhost:10000\", \"album_at_test1\", ['1', 'test2']] if atom0[0]=='1' and atom1[0]=='1' and atom0[1]=='test2' and atom1[1]=='bob' end;",
      "sbuffer <= (seed_from_test2_1_1_at_test2 * tags_at_test2 ).combos() do |atom0, atom1| [\"localhost:10000\", \"album_at_test1\", ['4', 'test2']] if atom0[0]=='4' and atom1[0]=='4' and atom0[1]=='test2' and atom1[1]=='bob' end;"],
      bud_rules_2

    runner1.tick
    runner2.tick
    
    # Check that fixpoint is reached
    runner1.tick
    runner2.tick
    assert_equal [["1", "test1"], ["1", "test2"], ["3", "test2"], ["4", "test2"]],
      runner1.tables[:album_at_test1].pro{|t| t.to_a }.sort
    runner1.tick
    runner2.tick
    assert_equal [["1", "test1"], ["1", "test2"], ["3", "test2"], ["4", "test2"]],
      runner1.tables[:album_at_test1].pro{|t| t.to_a }.sort
  end
  
end


# Test creation of push_elements tracking in the provenance graph via RuleTrace
# objects and ProofTrees object
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
    @pg_file = "test_build_proof_when_push_out"
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

  # Check the push_elements added to the proof tree and traces
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
    assert_equal(
      [["photos_at_testsf",
          "tags_at_testsf",
          "(photos_at_testsf*tags_at_testsf)",
          "(photos_at_testsf*tags_at_testsf*tags_at_testsf)"],
        ["images_at_testsf", "project[:photo, :owner, :useless]"]],
      runner.provenance_graph.traces.values.map{|rtrace| rtrace.print_push_elems})

    # Check facts stored in the proof trees
    assert_equal(
      [[0,
          [{[["1", "alice"], ["1", "alice"], ["1", "bob"]]=>["1", "alice"]},
            {[["5", "bob"], ["5", "alice"], ["5", "bob"]]=>["5", "bob"]}]],
        [1,
          [{[["4", "bob", "uselessfield"]]=>["4", "bob"]},
            {[["5", "bob", "uselessfield"]]=>["5", "bob"]}]]],
      runner.provenance_graph.traces.map do |rid,rtrace|
        [rid,rtrace.pushed_out_facts.map{|ptree| ptree.to_a_budstruct}]
      end)

    assert_equal ["(photos_at_testsf*tags_at_testsf*tags_at_testsf)",
      "project[photo, owner, useless]"],
      runner.provenance_graph.traces.map{|rid,rtrace| rtrace.print_last_push_elem }

    assert_equal [[:photos_at_testsf, :tags_at_testsf, :tags_at_testsf], [:images_at_testsf]],
      runner.provenance_graph.traces.map{|rid,rtrace| rtrace.sources}

    # Check the association between relation names in RuleTrace and facts in
    # ProofTrees
    assert_equal(
      [[:photos_at_testsf,
          [[{:photo=>"1", :owner=>"alice"}, [{:album_at_testsf=>["1", "alice"]}]],
            [{:photo=>"5", :owner=>"bob"}, [{:album_at_testsf=>["5", "bob"]}]]]],
        [:tags_at_testsf,
          [[{:img=>"1", :tag=>"alice"}, [{:album_at_testsf=>["1", "alice"]}]],
            [{:img=>"1", :tag=>"bob"}, [{:album_at_testsf=>["1", "alice"]}]],
            [{:img=>"5", :tag=>"alice"}, [{:album_at_testsf=>["5", "bob"]}]],
            [{:img=>"5", :tag=>"bob"}, [{:album_at_testsf=>["5", "bob"]}]]]],
        [:images_at_testsf,
          [[{:photo=>"4", :owner=>"bob", :useless=>"uselessfield"},
              [{:photos_at_testsf=>["4", "bob"]}]],
            [{:photo=>"5", :owner=>"bob", :useless=>"uselessfield"},
              [{:photos_at_testsf=>["5", "bob"]}]]]]],
      runner.provenance_graph.print_rel_index)
  end
end



# Check that all the push-joins are created from one rule, there is no reuse of
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
    @pg_file = "test_pushshjoin_shred_rules"
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
      runner.provenance_graph.traces.values.map{|rtrace| rtrace.push_elems}.flatten.map{|push_elem| push_elem.sanitize_push_elem_name } )

    assert_equal([],
      runner.provenance_graph.traces.values.map{|rtrace| rtrace.push_elems}.flatten.map{|push_elem| push_elem.object_id}.dups)
  end
end



# Simple test mostly used during development. It has only one rule.
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
    @pg_file = "test_trace_simple_derivation"
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