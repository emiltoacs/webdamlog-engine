$:.unshift File.dirname(__FILE__)
require_relative '../header_test'
require_relative '../../lib/webdamlog_runner'

require 'test/unit'

# Test program with seeds ie. relation or peer name variables
class TcWlSeed < Test::Unit::TestCase
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
    @pg_file = "test_seed_install_local"
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

  def test_seed_install_local
    
  end
  
end
