$:.unshift File.dirname(__FILE__)
require_relative '../header_test'
require_relative '../../lib/webdamlog_runner'

require 'test/unit'
require 'json'

DEBUG = false unless defined?(DEBUG)

# test projection of several relations atoms without any join in bud
class TcWlMeasure < Test::Unit::TestCase
  include MixinTcWlTest
  
  def setup
    @pg1 = <<-EOF
peer p1=localhost:11110;
collection ext per local1@p1(atom1*);
collection ext per local2@p1(atom1*);
collection ext per proj@p1(atom1*, atom2*);
fact local1@p1(1);
fact local2@p1(2);
fact local2@p1(3);
rule proj@p1($x,$y) :- local1@p1($x), local2@p1($y);
end
    EOF
    @username1 = "p1"
    @port1 = "11110"
    @pg_file1 = "test_tc_wl_wlbud_local_projection"
    File.open(@pg_file1,"w"){ |file| file.write @pg1 }
  end

  def teardown
    ObjectSpace.each_object(WLRunner) do |obj|
      clean_rule_dir obj.rule_dir
      obj.delete
    end
    ObjectSpace.garbage_collect
  end

  # Test the structure of the CSV created while reporting the time spend on each
  # step of each tick
  def test_measure

    begin
      runner1 = nil
      assert_nothing_raised do
        runner1 = WLRunner.create(@username1, @pg_file1, @port1, {:measure => true})
      end
      runner1.tick
      assert_equal [{:atom1=>"1",:atom2=>"2"},{:atom1=>"1",:atom2=>"3"}], runner1.tables[:proj_at_p1].map{ |t| Hash[t.each_pair.to_a] }
      assert_equal [{:atom1=>"1",:atom2=>"2"},{:atom1=>"1",:atom2=>"3"}], runner1.snapshot_facts(:proj_at_p1)
      runner1.tick
      runner1.tick
      assert File.exists? @pg_file1
      assert File.exists? runner1.measure_obj.measure_file
      hash_log = {}
      CSV.foreach(runner1.measure_obj.measure_file) do |row|
        hash_log[row.first] = row[1]
        assert_nothing_raised do
          Integer(row.first)
        end
        assert_kind_of String, row[1]
        assert_kind_of Array, JSON.parse(row[1])
      end
    ensure
      File.delete(@pg_file1) if File.exists?(@pg_file1)
      File.delete(runner1.measure_obj.measure_file) if File.exists?(runner1.measure_obj.measure_file)
      if EventMachine::reactor_running?
        runner1.stop true
      end
    end # begin
    
  end # def test_measure

end

