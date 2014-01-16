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
    @pg_file = "test_selfjoin_rewriting"
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
    # @scanners contains all the the collection push elements ie. the ScannersElement
    assert_equal([[:photos_at_testsf, :tags_at_testsf]],
      runner.scanners.map{|stratum| stratum.keys.map{|key| key[1]}})
    # @push_sorted_elems contains all the the PushElements order in a breadth-first order
    assert_equal([["photos_at_testsf",
          "tags_at_testsf",
          "(photos_at_testsf*tags_at_testsf)",
          "(photos_at_testsf*tags_at_testsf*tags_at_testsf)"]],
      runner.instance_variable_get(:@push_sorted_elems).map{|stratum| stratum.map {|pshelt| pshelt.elem_name.to_s.gsub(/:[0-9]*/,'')}})
    


  end


end