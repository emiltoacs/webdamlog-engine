$:.unshift File.dirname(__FILE__)
require_relative '../header_test'
require_relative '../../lib/webdamlog_runner'

require 'test/unit'

class TcDeletionTest < Test::Unit::TestCase
  include MixinTcWlTest

  def setup
    @pg1 = <<-EOF
peer p1=localhost:11110;
peer p2=localhost:11111;
collection ext per ext@p1(atom1*);
fact ext@p1(1);
fact ext@p1(2);
end
    EOF
    @username1 = "p1"
    @port1 = "11110"
    @pg_file1 = "test_deletion_test1"
    File.open(@pg_file1,"w"){ |file| file.write @pg1 }

    @pg2 = <<-EOF
peer p1=localhost:11110;
peer p2=localhost:11111;
collection ext per ext@p2(atom1*);
collection int int@p2(atom1*);
rule ext@p2($x) :- ext@p1($x);
rule int@p2($x) :- ext@p1($x);
end
    EOF
    @username2 = "p2"
    @port2 = "11111"
    @pg_file2 = "test_deletion_test2"
    File.open(@pg_file2,"w"){ |file| file.write @pg2 }
  end

  def teardown
    ObjectSpace.each_object(WLRunner){ |obj| obj.delete }
    ObjectSpace.garbage_collect
  end

  def test_remote_rules
    begin
      runner1 = nil
      runner2 = nil
      assert_nothing_raised do
        runner1 = WLRunner.create(@username1, @pg_file1, @port1, {noprovenance: true})
        runner2 = WLRunner.create(@username2, @pg_file2, @port2, {noprovenance: true})
      end
      runner1.tick
      runner2.tick
      runner1.tick
      runner2.tick
      runner1.tick
      runner2.tick
      assert_equal [{:atom1=>"1"}, {:atom1=>"2"}], 
        runner1.snapshot_facts(:ext_at_p1)
      assert_equal [{:atom1=>"1"}, {:atom1=>"2"}], 
        runner2.snapshot_facts(:int_at_p2)
      assert_equal [{:atom1=>"1"}, {:atom1=>"2"}], 
        runner2.snapshot_facts(:ext_at_p2)
      
      # simulate new fact to delete received from virtual peer p0
      runner1.tables[:chan] << ["localhost:10001",
        ["p0",
          "28000",
          {:declarations=>[],
            :facts=>{},
            :rules=>[],
            :facts_to_delete=>{"ext_at_p1"=>[["1"]]}
          }
        ]
      ]

      runner1.tick
      runner2.tick
      runner1.tick
      runner2.tick

      # TODO check the noprovenance and propagation of deletion, it seems that
      # sbuffer is not updated in the case of a deletion by delete_facts_in_coll
#      assert_equal [{:atom1=>"2"}], runner1.snapshot_facts(:ext_at_p1)      
#      assert_equal [{:atom1=>"2"}], runner2.snapshot_facts(:ext_at_p2)
#      assert_equal [{:atom1=>"2"}], runner2.snapshot_facts(:int_at_p2)
    ensure
      File.delete(@pg_file1) if File.exists?(@pg_file1)
      File.delete(@pg_file2) if File.exists?(@pg_file2)
      if EventMachine::reactor_running?
        runner1.stop
        runner2.stop true
      end
    end
  end
end
