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

# Test the treetop parser implementation in WLProgram and WLVocabulary objects
# instantiation.
#
# Given a webdamlog program in a text file, it should generate the right
# wl_program object.
#
# This test can be followed by tc_wl_wlbud_parse_program if succeed
#
class TcWlProgramTreetop < Test::Unit::TestCase
  include MixinTcWlTest

  # Test regex in ruby
  def test_010_regex_match
    assert_match(/[^\$][a-zA-Z0-9!?][a-zA-Z0-9!?_]*/, "this")
    assert_match(/[^\$][a-zA-Z0-9!?][a-zA-Z0-9!?_]*/, "this_is")
  end

  # Test creation of empty WLProgram with just relation declaration
  def test_020_empty_program
    program = nil
    File.open('test_string_1',"w"){ |file| file.write "collection ext persistent local@p1(atom1*);"}
    assert_nothing_raised {program = WLBud::WLProgram.new('the_peername', 'test_string_1', 'localhost', '11111', {:debug => true})}
    assert_not_nil program
    assert_equal 1, program.wlcollections.size
    assert_equal "local_at_p1", program.wlcollections.first[0]
    assert_equal 1, program.wlcollections.first[1].arity
    File.delete('test_string_1')
  end

  # word accept _ only in the middle of a name
  def test_030_string_word
    program = nil
    File.open('test_string_word',"w"){ |file| file.write "collection ext persistent local_1@p1(atom1*);"}
    assert_nothing_raised {program = WLBud::WLProgram.new('the_peername', 'test_string_word', 'localhost', '11111', {:debug => true})}
    File.open('test_string_word',"w"){ |file| file.write "collection ext persistent local_1_@p1(atom1*);"}
    assert_nothing_raised(WLBud::WLErrorGrammarParsing){program = WLBud::WLProgram.new('the_peername', 'test_string_word', 'localhost', '11111', {:debug => true}) }
    File.delete('test_string_word')
  end

  # Test if the collection type is well interpreted
  #
  def test_040_string_relation_type
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

  # test disambiguation mechanism
  def test_050_peername_namedsentence
    program = nil
    begin      
      # test disambiguation with real name
      File.open('test_050_peername_NamedSentence',"w"){ |file| file.write "collection ext persistent picture@myself(atom1*);"}
      assert_nothing_raised {program = WLBud::WLProgram.new('myself', 'test_050_peername_NamedSentence', 'localhost', '4100', {:debug => true})}
      rel = program.wlcollections["picture_at_myself"]
      assert_not_nil rel
      assert_kind_of WLBud::WLCollection, rel
      program.disamb_peername!(program.wlcollections["picture_at_myself"])
      assert_equal "myself", program.wlcollections["picture_at_myself"].peername

      # test disambiguation with alias
      File.open('test_050_peername_NamedSentence',"w"){ |file| file.write "collection ext persistent picture@local(atom1*);"}
      assert_nothing_raised {program = WLBud::WLProgram.new('myself', 'test_050_peername_NamedSentence', 'localhost', '4100', {:debug => true})}
      rel = program.wlcollections["picture_at_myself"]
      assert_not_nil rel
      assert_kind_of WLBud::WLCollection, rel
      program.disamb_peername!(program.wlcollections["picture_at_myself"])
      assert_equal "myself", program.wlcollections["picture_at_myself"].peername

      # test disambiguation with alias in rules
      pg = <<-EOF
    peer sigmod_peer = localhost:4100;
    peer myself = localhost:4150;
    collection ext persistent picture@myself(title*, owner*, _id*, image_url*); #image data fields not added
    collection ext persistent picturelocation@me(_id*, location*);
    collection ext persistent rating@local(_id*, rating*);
    collection ext persistent comment@myself(_id*,author*,text*,date*);
    collection ext persistent contact@myself(username*, peerlocation*, online*, email*, facebook*);
    rule contact@local($username, $peerlocation, $online, $email, $facebook):-contact@sigmod_peer($username, $peerlocation, $online, $email, $facebook);
    end
      EOF
      File.open('test_050_peername_NamedSentence',"w"){ |file| file.write pg}
      program = nil
      assert_nothing_raised do
        program = WLBud::WLProgram.new(
          'myself',
          'test_050_peername_NamedSentence',
          'localhost',
          '4150',
          {:debug => true} )
      end
      # test collection with alias me
      rel = program.wlcollections["picturelocation_at_myself"]
      assert_not_nil rel
      assert_kind_of WLBud::WLCollection, rel
      assert_equal "myself", rel.peername
      # test collection with alias local
      rel = program.wlcollections["rating_at_myself"]
      assert_not_nil rel
      assert_kind_of WLBud::WLCollection, rel
      assert_equal "myself", rel.peername
      # test collection without alias
      rel = program.wlcollections["contact_at_myself"]
      assert_not_nil rel
      assert_kind_of WLBud::WLCollection, rel
      assert_equal "myself", rel.peername
      # test rule
      rule = program.rule_mapping[1][0]
      assert_not_nil rule
      assert_kind_of WLBud::WLRule, rule
      assert_equal ["myself", "sigmod_peer"], rule.peername
    ensure
      File.delete('test_050_peername_NamedSentence') if File.exists?('test_050_peername_NamedSentence')
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
      program.wlfacts.each { |fact| assert_equal "local_at_p1",fact.fullrelname }
      program.wlfacts.each_with_index { |fact,num|
        assert_equal [(num+1).to_s], fact.content
      }
      # assert_equal 1, program.wl
    ensure
      File.delete('test_program_1') if File.exists?('test_program_1')
    end
  end # test_200_program_1

  # EOL comments with # or // or C-style comment on multiple lines /* ... */.
  # C-style comment should start on a line without a previous  webdamlog command
  # ie. no ';' could precede a '/*' on the same line
  def test_comment    
    prog = <<-EOF
# comment should start with # // for end of line comment or /* */ for C-style comment
peer sigmod_peer = localhost:10000;
// some other comments here
# comments again
peer p1=localhost:11111;
peer p2=localhost:11112;
peer p3=localhost:11113;
peer p4=localhost:11114;
/* some C-style comment
on multiple lines
...
until here */
collection extensional persistent local@p1(atom1*);
collection ext local_2@p1(atom1*);
collection int joindelegated@p1(atom1*);
collection intermediary relintermed@p1(atom1*);
collection inter per relintermed_2@p1(atom1*);
fact local@p1(1);
fact local@p1(2);
fact local@p1(3);
fact local@p1(4);
rule joindelegated@p1($x):- local@p1($x),
  delegated@p2($x),
  delegated@p3($x), 
  delegated@p4($x);
end
    EOF
    begin
      File.open('test_program_2',"w"){ |file| file.write prog}
      program = nil
      assert_nothing_raised do
        program = WLBud::WLProgram.new(
          'the_peername',
          'test_program_2',
          'localhost',
          '11111',
          {:debug => true} )
      end
      assert_equal 5, program.wlcollections.length
      assert_equal 4, program.wlfacts.length
      assert_equal 2, program.rule_mapping.size
    ensure
      File.delete('test_program_2') if File.exists?('test_program_2')
    end
  end # test_comment
end



# Put here some sample test program that must be correct syntactically
class TcParseProgram < Test::Unit::TestCase
  include MixinTcWlTest  

  # Check collection declaration syntax on multiple lines with special character
  # in attributes
  def test_sample_program
    prog = <<-EOF
peer sigmod_peer = localhost:10000;
collection ext persistent contact@local(username*,    peerlocation*
, online*,email*, facebook*);
fact contact@local(sigmod_peer, localhost:10000, false, none, none);
fact contact@local(Jules, localhost:10000, false, "jules.testard@mail.mcgill.ca", "Jules Testard");
end
    EOF
    begin
      File.open('test_program_2',"w"){ |file| file.write prog}
      program = nil
      assert_nothing_raised do
        program = WLBud::WLProgram.new(
          'sigmod_peer',
          'test_program_2',
          'localhost',
          '11111',
          {:debug => true} )
      end
      assert_equal 2, program.wlfacts.size
      assert_equal ["sigmod_peer", "localhost:10000", "false", "none", "none"], program.wlfacts[0].content      
      assert_equal ["Jules", "localhost:10000", "false", "jules.testard@mail.mcgill.ca", "Jules Testard"], program.wlfacts[1].content
      assert_equal 5, program.wlcollections.first[1].arity
      assert_equal ["username", "peerlocation", "online", "email", "facebook"], program.wlcollections["contact_at_sigmod_peer"].fields
    ensure
      File.delete('test_program_2') if File.exists?('test_program_2')
    end
  end
end


# Test variables in rules and rule rewriting in rule_mapping
#
class TcRulesWLVocabulary < Test::Unit::TestCase
  include MixinTcWlTest 
  
  def test_vocabulary_rules
    prog = <<-EOF
peer sigmod_peer = localhost:10000;
collection ext persistent contact@local(username*, peerlocation*, online*, email*, facebook*);
rule contact@local($username, $peerlocation, $online, $email, none):-contact@sigmod_peer($username, $peerlocation, $online, $email, none);
end
    EOF
  
    File.open('test_program_2',"w"){ |file| file.write prog}
    program = nil
    assert_nothing_raised do
    program = WLBud::WLProgram.new(
      'the_peername',
      'test_program_2',
      'localhost',
      '11111',
      {:debug => true} )
    end
    assert_equal 2, program.rule_mapping.size

    delegation = "rule contact@local($username, $peerlocation, $online, $email, none):-contact@sigmod_peer($username, $peerlocation, $online, $email, none);"

    keys = program.rule_mapping.keys
    assert_equal 1, keys[0]
    assert_equal delegation, keys[1]

    values = program.rule_mapping.values
    assert_equal 2, values[0].size
    assert_kind_of(WLBud::WLRule, values[0].first)
    assert_equal delegation, values[0][1]

    assert_equal 1, values[1].size
    assert_kind_of String, values[1].first
    assert_equal delegation, values[1].first

    assert_equal 4, program.rule_mapping[1].first.head.rfields.variables.length
    assert_equal 5, program.rule_mapping[1].first.head.rfields.fields.length
  ensure
    File.delete('test_program_2') if File.exists?('test_program_2')
  end
end
