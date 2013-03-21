# ####License####
#  File name tc_wl_program_treetop.rb
#  Copyright © by INRIA
#
#  Contributors : Webdam Team <webdam.inria.fr>
#       Emilien Antoine <emilien[dot]antoine[@]inria[dot]fr>
#
#   WebdamLog - Aug 15, 2012
#
#   Encoding - UTF-8
# ####License####
$:.unshift File.dirname(__FILE__)
require 'header_test'
require 'generator'
  
# Test the treetop parser implementation in WLProgram and WLVocabulary objects
# instantiation.
#
# Given a webdamlog program in a text file, it should generate the right
# wl_program object.
#
# This test can be followed by tc_wl_wlbud_parse_program id succeed
#
class TcWlProgramTreetop < Test::Unit::TestCase
  include MixinTcWlTest

  # Test regex in ruby
  def test_010_regex_match
    assert_match(/[^\$][a-zA-Z0-9!?][a-zA-Z0-9!?_]*/, "this")
    assert_match(/[^\$][a-zA-Z0-9!?][a-zA-Z0-9!?_]*/, "this_is")
  end

  # Test creation of empty WLProgram
  def test_020_string_1
    program = nil
    File.open('test_string_1',"w"){ |file| file.write "collection ext persistent local@p1(atom1*);"}
    assert_nothing_raised {program = WLBud::WLProgram.new('the_peername', 'test_string_1', 'localhost', '11111', {:debug => true})}
    assert_not_nil program
    File.delete('test_string_1')
  end

  # word accept _ only in the middle of a name
  #
  def test_030_string_word
    program = nil
    File.open('test_string_word',"w"){ |file| file.write "collection ext persistent local_1@p1(atom1*);"}
    assert_nothing_raised {program = WLBud::WLProgram.new('the_peername', 'test_string_word', 'localhost', '11111', {:debug => true})}
    File.open('test_string_word',"w"){ |file| file.write "collection ext persistent local_1_@p1(atom1*);"}
    assert_raise(WLBud::WLErrorGrammarParsing){program = WLBud::WLProgram.new('the_peername', 'test_string_word', 'localhost', '11111', {:debug => true}) }
    File.delete('test_string_word')
  end

  # Test if the collection type is well interpreted
  #
  def test_040_string_rel_type
    program = nil
    begin
      File.open('test_string_rel_type',"w"){ |file| file.write "collection ext persistent local_1@p1(atom1*);"}
      assert_nothing_raised {program = WLBud::WLProgram.new('the_peername', 'test_string_rel_type', 'localhost', '11111', {:debug => true})}
      assert_equal :Extensional, program.wlcollections.first[1].get_type
      assert_kind_of WLBud::WLExtensional, program.wlcollections.first[1].rel_type
      assert program.wlcollections.first[1].persistent?
      File.open('test_string_rel_type',"w"){ |file| file.write "collection extensional local_1@p1(atom1*);"}
      assert_nothing_raised{ program = WLBud::WLProgram.new('the_peername', 'test_string_rel_type', 'localhost', '11111', {:debug => true}) }
      assert_kind_of WLBud::WLExtensional, program.wlcollections.first[1].rel_type
      assert (not program.wlcollections.first[1].persistent?)
      File.open('test_string_rel_type',"w"){ |file| file.write "collection intensional local_1@p1(atom1*);"}
      assert_nothing_raised{ program = WLBud::WLProgram.new('the_peername', 'test_string_rel_type', 'localhost', '11111', {:debug => true}) }
      assert_kind_of WLBud::WLIntensional, program.wlcollections.first[1].rel_type
      assert (not program.wlcollections.first[1].persistent?)
      File.open('test_string_rel_type',"w"){ |file| file.write "collection int local_1@p1(atom1*);"}
      assert_nothing_raised{ program = WLBud::WLProgram.new('the_peername', 'test_string_rel_type', 'localhost', '11111', {:debug => true}) }
      assert_kind_of WLBud::WLIntensional, program.wlcollections.first[1].rel_type
      assert (not program.wlcollections.first[1].persistent?)
      File.open('test_string_rel_type',"w"){ |file| file.write "collection intermediary local_1@p1(atom1*);"}
      assert_nothing_raised{ program = WLBud::WLProgram.new('the_peername', 'test_string_rel_type', 'localhost', '11111', {:debug => true}) }
      assert_kind_of WLBud::WLIntermediary, program.wlcollections.first[1].rel_type
      assert (not program.wlcollections.first[1].persistent?)
      File.open('test_string_rel_type',"w"){ |file| file.write "collection inter local_1@p1(atom1*);"}
      assert_nothing_raised{ program = WLBud::WLProgram.new('the_peername', 'test_string_rel_type', 'localhost', '11111', {:debug => true}) }
      assert_kind_of WLBud::WLIntermediary, program.wlcollections.first[1].rel_type
      assert (not program.wlcollections.first[1].persistent?)
      File.open('test_string_rel_type',"w"){ |file| file.write "collection intermediary persistent local_1@p1(atom1*);"}
      assert_nothing_raised{ program = WLBud::WLProgram.new('the_peername', 'test_string_rel_type', 'localhost', '11111', {:debug => true}) }
      assert_kind_of WLBud::WLIntermediary, program.wlcollections.first[1].rel_type
      assert (program.wlcollections.first[1].persistent?)
      File.open('test_string_rel_type',"w"){ |file| file.write "collection inter per local_1@p1(atom1*);"}
      assert_nothing_raised{ program = WLBud::WLProgram.new('the_peername', 'test_string_rel_type', 'localhost', '11111', {:debug => true}) }
      assert_kind_of WLBud::WLIntermediary, program.wlcollections.first[1].rel_type
      assert (program.wlcollections.first[1].persistent?)
    ensure
      File.delete('test_string_rel_type') if File.exists?('test_string_rel_type')
    end
  end

  # This is just a test file, in regular use it is forbidden to declare
  # intermediary relation
  STR1 = <<EOF
peer p1=localhost:11111;
peer p2=localhost:11112;
peer p3=localhost:11113;
peer p4=localhost:11114;
collection extensional persistent local@p1(atom1*);
collection ext local_2@p1(atom1*);
collection int joindelegated@p1(atom1*);
collection intermediary relintermed@p1(atom1*);
collection inter per relintermed_2@p1(atom1*);
fact local@p1(1);
fact local@p1(2);
fact local@p1(3);
fact local@p1(4);
rule joindelegated@p1($x):- local@p1($x),delegated@p2($x),delegated@p3($x),delegated@p4($x);
end
EOF
  # Test parsing and WLVocabulary instantiation of a simple init program file
  def test_200_program_1
    begin
      File.open('test_program_1',"w"){ |file| file.write STR1}
      program = nil
      assert_nothing_raised do
        program = WLBud::WLProgram.new(
          'the_peername',
          'test_program_1',
          'localhost',
          '11111',
          {:debug => true} )
      end
      assert_not_nil program
      assert_equal 5, program.wlcollections.length
      assert_equal :Extensional, program.wlcollections["local_at_p1"].get_type
      assert program.wlcollections["local_at_p1"].persistent?
      assert_equal :Extensional, program.wlcollections["local_2_at_p1"].get_type
      assert (not program.wlcollections["local_2_at_p1"].persistent?)
      assert_equal :Intensional, program.wlcollections["joindelegated_at_p1"].get_type
      assert (not program.wlcollections["local_2_at_p1"].persistent?)
      assert_equal :Intermediary, program.wlcollections["relintermed_at_p1"].get_type
      assert (not program.wlcollections["relintermed_at_p1"].persistent?)
      assert_equal :Intermediary, program.wlcollections["relintermed_2_at_p1"].get_type
      assert program.wlcollections["relintermed_2_at_p1"].persistent?
      assert_equal 4, program.wlfacts.length
      program.wlfacts.each { |fact| assert_equal "local_at_p1",fact.relname }
      SyncEnumerator.new(program.wlfacts,1..4).each { |fact,num|
        assert_equal [num.to_s], fact.content
      }
      # #assert_equal 1, program.wl
    ensure
      File.delete('test_program_1') if File.exists?('test_program_1')
    end
  end # test_200_program_1
end

# Put here some sample test program that must be correct syntactically
class TcParseProgram < Test::Unit::TestCase
  include MixinTcWlTest

  PROG = <<-EOF
peer sigmod_peer = localhost:10000;
collection ext persistent contact@local(username*, peerlocation*, online*, email*, facebook*);
fact contact@local(sigmod_peer, localhost:10000, false, none, none);
end
  EOF

  # Use to check the bootstrap program launched by the wepic app
  def test_sample_program
    begin
      File.open('test_program_2',"w"){ |file| file.write PROG}
      program = nil
      assert_nothing_raised do
        program = WLBud::WLProgram.new(
          'the_peername',
          'test_program_2',
          'localhost',
          '11111',
          {:debug => true} )
      end
    ensure
      File.delete('test_program_2') if File.exists?('test_program_2')
    end
  end
end


class TcWLVocabulary < Test::Unit::TestCase
  include MixinTcWlTest

  PROG = <<-EOF
peer sigmod_peer = localhost:10000;
collection ext persistent contact@local(username*, peerlocation*, online*, email*, facebook*);
rule contact@local($username, $peerlocation, $online, $email, none):-contact@sigmod_peer($username, $peerlocation, $online, $email, none);
end
  EOF

  def test_vocabulary
    File.open('test_program_2',"w"){ |file| file.write PROG}
    program = nil
    assert_nothing_raised do
      program = WLBud::WLProgram.new(
        'the_peername',
        'test_program_2',
        'localhost',
        '11111',
        {:debug => true} )
    end
    program.original_rules.each_key do |r|      
      assert 4, r.head.rfields.variables.length
      assert 1, r.head.rfields.fields
    end
  ensure
    File.delete('test_program_2') if File.exists?('test_program_2')
  end
  
end