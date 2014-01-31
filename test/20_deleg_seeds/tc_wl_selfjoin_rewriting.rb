$:.unshift File.dirname(__FILE__)
require_relative '../header_test'
require_relative '../../lib/webdamlog_runner'

require 'test/unit'

# Test to check that self joins in wdl rules does not leads to wrong rules in
# bud. When a variable occurs in two different atoms of wdl rules with the same
# relation name, the standard rewriting in bud with joins specified as argument
# of combos methods does not work because of ambiguity on relation name. Hence
# the conditions should be specified in the ruby block with IF statements.
class TcWWlSelfjoinRewriting < Test::Unit::TestCase
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

  # Check that the rewriting of wdl rule into bud is eliminating self join
  # problem
  def test_self_join_rewriting
    runner = WLRunner.create(@username, @pg_file, @port)
    runner.tick
    rule_dir = runner.rule_dir
    assert File.directory?(rule_dir)
    bud_rule = ""
    Dir.chdir(rule_dir) do
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
    assert_equal [["1", "alice"], ["6", "bob"]], runner.tables[:album_at_testsf].pro { |t| t.to_a }.sort
  end

  # Debug test the content of dictionaries in self join rules
  def test_wlprogram_selfjoin_rewriting
    runner = WLRunner.create(@username, @pg_file, @port)
    prog = runner.wl_program
    assert_equal 1, prog.rule_mapping.length
    rule = prog.rule_mapping.first[1].first
    assert_equal "rule album@testsf($img, $owner) :- photos@testsf($img, $owner), tags@testsf($img, \"alice\"), tags@testsf($img, \"bob\");",
      rule.show_wdl_format
    rule.make_dictionaries
    assert_equal(
      {"photos_at_testsf"=>[0], "tags_at_testsf"=>[1, 2]},
      rule.dic_relation_name)
    assert_equal(
      {0=>"photos_at_testsf", 1=>"tags_at_testsf", 2=>"tags_at_testsf"},
      rule.dic_invert_relation_name)
    assert_equal(
      {"$img"=>["0.0", "1.0", "2.0"], "$owner"=>["0.1"]},
      rule.dic_wlvar)

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
    assert_equal "album_at_testsf <+ (photos_at_testsf * tags_at_testsf * tags_at_testsf ).combos(photos_at_testsf.photo => tags_at_testsf.img,photos_at_testsf.photo => tags_at_testsf.img) do |atom0, atom1, atom2| [atom0[0], atom0[1]] if atom1[1]=='alice' and atom2[1]=='bob' and atom1[0]==atom2[0] end;",
      bud_rule
  end

end
