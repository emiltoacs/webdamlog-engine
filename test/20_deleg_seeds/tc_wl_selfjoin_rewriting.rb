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
collection ext per photos@testsf(photo*);
collection ext per tags@testsf(img*,tag*);
collection ext per album@testsf(pic*);
fact photos@testsf(1);
fact photos@testsf(2);
fact photos@testsf(3);
fact photos@testsf(4);
fact photos@testsf(5);
fact photos@testsf(6);
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
rule album@testsf($img) :- photos@testsf($img), tags@testsf($img,"alice"), tags@testsf($img,"bob");
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
    Bud::stop_em_loop
    EventMachine::reactor_thread.join
    ObjectSpace.garbage_collect
    File.delete(@pg_file) if File.exists?(@pg_file)
  end

  # Check that the rewriting of wdl rule into bud is eliminating self join
  # problem
  def test_self_join_rewriting
    runner = WLRunner.create(@username, @pg_file, @port)  
    rule_dir = runner.rule_dir
    runner.tick

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
    assert_equal "album_at_testsf <= (photos_at_testsf * tags_at_testsf * tags_at_testsf ).combos(photos_at_testsf.photo => tags_at_testsf.img,photos_at_testsf.photo => tags_at_testsf.img) do |atom0, atom1, atom2| [atom0[0]] if atom1[1]=='alice' and atom2[1]=='bob' end;",
      bud_rule
  end

  

end
