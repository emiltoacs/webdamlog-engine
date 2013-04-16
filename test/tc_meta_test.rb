# ####License####
#  File name tc_test_test.rb
#  Copyright © by INRIA
# 
#  Contributors : Webdam Team <webdam.inria.fr>
#       Emilien Antoine <emilien[dot]antoine[@]inria[dot]fr>
# 
#   WebdamLog - Jun 27, 2012
# 
#   Encoding - UTF-8
# ####License####
$:.unshift File.dirname(__FILE__)
require 'header_test'
require 'rexml/syncenumerator'

class TestMeta < Test::Unit::TestCase

  TEST_FILENAME = "prog"

  def teardown
    File.delete TEST_FILENAME if File.exist? TEST_FILENAME
  end

  # Test how to write and delete a program file
  #
  def test_program_file_writing
    str = <<EOF
peer p1=localhost:12345;
peer p2=localhost:12346;
peer p3=localhost:12347;

collection persistent child@p1(child*,father*,mother*);
collection descendant@p1(child*,parent*);
collection sibling@p1(bro1*,bro2*);
collection cousin@p1(cou1*,cou2*);
collection direct_child@p1(child*,parent*);
collection descendantJoin@p3(child*,parent*);

fact child@p1(e,F,M);
fact child@p1(E,F,M);
fact child@p1(F,FF,MF);

rule direct_child@p1($a,$b):-child@p1($a,$b,_);
rule direct_child@p1($a,$b):-child@p1($a,_,$b);

rule child@p1($x,$y,$z):-child@p2($x,$y,$z);

rule descendant@p1($x,$y):-child@p1($x,$y,_);
rule descendant@p1($x,$y):-child@p1($x,_,$y);
rule descendant@p1($a,$c):- child@p1($a,$b,_),descendant@p1($b,$c);
rule descendant@p1($a,$c):- child@p1($a,_,$b),descendant@p1($b,$c);

rule descendantJoin@p3($a,$c):- direct_child@p1($a,$b),child@p2($b,$c,_);
rule descendantJoin@p3($a,$c):- direct_child@p1($a,$b),child@p2($b,_,$c);
end
EOF
    
    File.open(TEST_FILENAME,"w"){ |file| file.write str}
    myfile = File.open(TEST_FILENAME,"r")
    lines = myfile.readlines
    assert(str.lines.count!=0, "an empty string is not a valide program")
    assert_equal lines.size, str.lines.count
    REXML::SyncEnumerator.new(lines,str.lines.to_a).each { |l,s|
      assert_equal l, s
    }
  end
end
