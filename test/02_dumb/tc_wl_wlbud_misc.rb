$:.unshift File.dirname(__FILE__)
require_relative '../header_test'

# To test miscellaneous WLBud methods
#
class TcWlWlbudMisc < Test::Unit::TestCase
  
  #@@first_test=true
  NUMBER_OF_TEST_PG=1
  TEST_FILENAME="test_filename_"
  PREFIX_PORT_NUMBER="1111"

  # Standard initialization of wl peer with a program and default ip and port
  # number
  #
  class Peer1Local < WLBud::WL
    STR0 = <<EOF
peer p1=localhost:11111;
peer p2=localhost:11112;
collection ext persistent local@p1(atom1*);
collection ext persistent local2@p1(atom1*);
collection ext persistent local3@p1(atom1*);
collection ext join_delegated@p1(atom1*);
fact local@p1(1);
fact local@p1(2);
fact local@p1(3);
fact local@p1(4);
rule join_delegated@p1($x):- local@p1($x),delegated@p2($x);
rule join_delegated@p1($x):- local2@p1($x),delegated@p2($x);
rule join_delegated@p1($x):- local3@p1($x),delegated@p2($x);
end
EOF
    def initialize(peername, options={})
      File.open("#{TEST_FILENAME}0","w"){ |file| file.write STR0 }
      super(peername, "#{TEST_FILENAME}0", options)
    end
  end

  def setup
    #    if @@first_test
    #      @@first_test=false
    @wloptions = Struct.new :ip, :port, :wl_test
    #    end
    (0..NUMBER_OF_TEST_PG-1).each do |i|
      eval("#{TEST_FILENAME}#{i} = \"prog_#{i}\"")
      eval("@tcoption#{i} = @wloptions.new \"localhost\",
 \"#{PREFIX_PORT_NUMBER}#{i}\", \"true\"")
    end
  end

  def teardown
    #    self.class.constants.each{ |item| p "#{item} : #{eval(item)}"if item=~/FILENAME/ }
    (0..NUMBER_OF_TEST_PG-1).each do |i|
      #      p Dir.entries((File.dirname("TEST_FILENAME#{i}"))).inspect+" in dir"
      #      p File.exist?(eval("TEST_FILENAME#{i}")).to_s+" exists?"
      #      p File.expand_path(File.dirname("TEST_FILENAME#{i}")).to_s+" dirname"
      eval("File.delete \"#{TEST_FILENAME}#{i}\" if File.exist? \"#{TEST_FILENAME}#{i}\"")
      #      p File.exist?(eval("TEST_FILENAME#{i}")).to_s+" exists?"
    end
  end

  # Test if the rule_dir is properly erased
  #
  def test_1_clear_rule_dir
    (wl_peer ||= [] ) << Peer1Local.new('p1', Hash[@tcoption0.each_pair.to_a])
    wl_peer.each do |item|
      p item.rule_dir if $test_verbose
      assert item.clear_rule_dir
    end
  ensure
    if EventMachine::reactor_running?
      wl_peer[0].stop(true) # here I also stop EM to be clean
    end
  end
end
