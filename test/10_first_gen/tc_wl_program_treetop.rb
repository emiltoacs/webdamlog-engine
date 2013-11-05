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
require_relative '../header_test'

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
    File.open('test_string_1',"w") do |file|
      file.write <<-END
collection ext persistent local@p1(atom1*);
collection ext persistent localempty@p1();
      END
    end
    assert_nothing_raised {program = WLBud::WLProgram.new('the_peername', 'test_string_1', 'localhost', '11111', {:debug => true})}
    assert_not_nil program
    assert_equal 2, program.wlcollections.size
    assert_equal "local_at_p1", program.wlcollections.first[0]
    assert_equal "localempty_at_p1", program.wlcollections.to_a[1][0]
    assert_equal 1, program.wlcollections.first[1].arity
    assert_equal 0, program.wlcollections.to_a[1][1].arity
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

  # Facts arity 0 not allowed
  def test_035_arity_0
    program = nil
    File.open('test_035_arity_0',"w") do |file|
      file.write <<-END
collection ext persistent local@p1();
end
      END
    end
    assert_nothing_raised {program = WLBud::WLProgram.new('the_peername', 'test_035_arity_0', 'localhost', '11111', {:debug => true})}
    assert_equal "local_at_p1", program.wlcollections.first[0]
    assert_equal 0, program.wlcollections.first[1].arity
    assert_equal 0, program.wlfacts.size
    File.delete('test_035_arity_0')
  end

  # Test if the collection type is well interpreted
  #
  def test_040_string_relation_type
    program = nil
    begin
      # extensional persistent
      File.open('test_string_rel_type',"w"){ |file| file.write "collection ext persistent local_1@p1(atom1*);"}
      assert_nothing_raised {program = WLBud::WLProgram.new('the_peername', 'test_string_rel_type', 'localhost', '11111', {:debug => true})}
      assert_equal :Extensional, program.wlcollections.first[1].get_type
      assert program.wlcollections.first[1].rel_type.extensional?
      assert_kind_of WLBud::WLExtensional, program.wlcollections.first[1].rel_type
      assert program.wlcollections.first[1].persistent?
      # extensional
      File.open('test_string_rel_type',"w"){ |file| file.write "collection extensional local_1@p1(atom1*);"}
      assert_nothing_raised{ program = WLBud::WLProgram.new('the_peername', 'test_string_rel_type', 'localhost', '11111', {:debug => true}) }
      assert_kind_of WLBud::WLExtensional, program.wlcollections.first[1].rel_type
      assert (not program.wlcollections.first[1].persistent?)
      # intensional
      File.open('test_string_rel_type',"w"){ |file| file.write "collection intensional local_1@p1(atom1*);"}      
      assert_nothing_raised{ program = WLBud::WLProgram.new('the_peername', 'test_string_rel_type', 'localhost', '11111', {:debug => true}) }
      assert_equal :Intensional, program.wlcollections.first[1].get_type
      assert program.wlcollections.first[1].rel_type.intensional?
      assert_kind_of WLBud::WLIntensional, program.wlcollections.first[1].rel_type
      assert (not program.wlcollections.first[1].persistent?)
      File.open('test_string_rel_type',"w"){ |file| file.write "collection int local_1@p1(atom1*);"}
      assert_nothing_raised{ program = WLBud::WLProgram.new('the_peername', 'test_string_rel_type', 'localhost', '11111', {:debug => true}) }
      assert_kind_of WLBud::WLIntensional, program.wlcollections.first[1].rel_type
      assert (not program.wlcollections.first[1].persistent?)
      # intermediary
      File.open('test_string_rel_type',"w"){ |file| file.write "collection intermediary local_1@p1(atom1*);"}
      assert_nothing_raised{ program = WLBud::WLProgram.new('the_peername', 'test_string_rel_type', 'localhost', '11111', {:debug => true}) }
      assert program.wlcollections.first[1].rel_type.intermediary?
      assert_kind_of WLBud::WLIntermediary, program.wlcollections.first[1].rel_type
      assert (not program.wlcollections.first[1].persistent?)
      File.open('test_string_rel_type',"w"){ |file| file.write "collection inter local_1@p1(atom1*);"}
      assert_nothing_raised{ program = WLBud::WLProgram.new('the_peername', 'test_string_rel_type', 'localhost', '11111', {:debug => true}) }
      assert_kind_of WLBud::WLIntermediary, program.wlcollections.first[1].rel_type
      assert (not program.wlcollections.first[1].persistent?)
      # intermediary persistent
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

  # Test rule syntax
  #
  # FIXME semi-colon ';' in comment are still interpreted as and of instruction
  # because of the readline technique to parse files.
  #
  # FIXME relax parser constraint to accept _at_ instead of @ as relation to
  # peer delimiter
  def test_045_rule
    program = nil
    File.open('test_045_rules',"w") do |file|
      file.write <<-END
collection ext persistent local1@p1();
collection ext persistent local2@p1();
rule local1@p1($X):-local2@p1($X);
#rule local1_at_p1($Y):-local2@p1($Y)
#last rule doesn't work because of _at_ format
      END
    end
    program = WLBud::WLProgram.new('p1', 'test_045_rules', 'localhost', '11111', {:debug => true})
    assert_equal "local1_at_p1", program.wlcollections.first[0]
    assert_equal 0, program.wlcollections.first[1].arity
    assert_equal 0, program.wlfacts.size
    File.delete('test_045_rules')
  end

  # test disambiguation mechanism
  def test_050_peername_namedsentence_disamb
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
    peer sigmod_peer = ec2-54-224-165-123.compute-1.amazonaws.com:4100;
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

  # test disambiguation mechanism
  def test_060_fact_disamb
    program = nil
    begin
      # test disambiguation with alias in rules
      pg = <<-EOF
    peer sigmod_peer = localhost:4100;
    peer myself = localhost:4150;
    collection ext persistent picture@local(title*, owner*, _id*, image_url*);
    fact picture@local(sigmod,local,12347,"http://www.seeklogo.com/images/A/Acm_Sigmod-logo-F12330F5BD-seeklogo.com.gif");
    fact picture@local(webdam,local,12348,"http://www.cs.tau.ac.il/workshop/modas/webdam3.png");
    end
      EOF
      File.open('test_060_fact_disamb',"w"){ |file| file.write pg}
      program = nil
      # #assert_nothing_raised do
      program = WLBud::WLProgram.new(
        'myself',
        'test_060_fact_disamb',
        'localhost',
        '4150',
        {:debug => true} )
      # #end test collection with alias me
      rel = program.wlcollections["picture_at_myself"]
      assert_not_nil rel
      assert_kind_of WLBud::WLCollection, rel
      assert_equal "myself", rel.peername
      fact = program.wlfacts
      assert_not_nil fact
      # #assert_kind_of WLBud::WLFacts, fact
      assert_equal ["picture_at_myself( sigmod, myself, 12347, http://www.seeklogo.com/images/A/Acm_Sigmod-logo-F12330F5BD-seeklogo.com.gif ) ;",
        "picture_at_myself( webdam, myself, 12348, http://www.cs.tau.ac.il/workshop/modas/webdam3.png ) ;"],
        fact.map { |fact| fact.show_wdl_format }
      assert_equal [["sigmod",
          "myself",
          "12347",
          "http://www.seeklogo.com/images/A/Acm_Sigmod-logo-F12330F5BD-seeklogo.com.gif"],
        ["webdam",
          "myself",
          "12348",
          "http://www.cs.tau.ac.il/workshop/modas/webdam3.png"]], fact.map { |fact| fact.content }

    ensure
      File.delete('test_060_fact_disamb') if File.exists?('test_060_fact_disamb')
    end
  end


  # This is just a test file, in regular use it is forbidden to declare
  # intermediary relation
  STR1 = <<-EOF
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
  def test_300_comment
    prog = <<-EOF
# comment should start with # // for end of line comment or /* */ for C-style comment
peer sigmod_peer = localhost:10000;
// some other comments here
# comments again
peer p1=localhost:11111;
peer p2=localhost:11112; /* comment start at end of instruction
 and finish on another line */
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
  delegated@p2($x), # inline eol comment in the middle of a rule
  delegated@p3($x), 
  delegated@p4($x);
end
    EOF
    begin
      File.open('test_program_2',"w"){ |file| file.write prog}
      program = nil
      program = WLBud::WLProgram.new(
        'the_peername',
        'test_program_2',
        'localhost',
        '11111',
        {:debug => true})
      assert_equal 5, program.wlcollections.length
      assert_equal 4, program.wlfacts.length
      assert_equal 1, program.wlrules.size
      assert_equal 1, program.rule_mapping.size
    ensure
      File.delete('test_program_2') if File.exists?('test_program_2')
    end
  end # test_comment
end # class


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
fact contact@local(sigmod_peer, "localhost:10000", false, none, none);
fact contact@local(Jules, "localhost:10000", false, "jules.testard@mail.mcgill.ca", "Jules Testard");
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

  # load the treetop grammar file and create the treetop parser object by hand
  # (ie. without polyglot) then parse the program given in example to test
  # custom grammar
  #
  # note the special way to read the program thanks to IO.readlines with ;
  # separator instead of the wlprogram.parse_lines method
  def test_load_treetop_grammar
    prog = <<-EOF
peer sigmod_peer = localhost:10000;
collection ext persistent contact@local(username*,    peerlocation*
, online*,email*, facebook*);
fact contact@local(sigmod_peer, "localhost:10000", false, none, none);
fact contact@local(Jules, "localhost:10000", false, "jules.testard@mail.mcgill.ca", "Jules Testard");
    EOF
    begin
      File.open('test_program_2',"w"){ |file| file.write prog}
      Treetop.load(File.join(File.dirname(__FILE__), "..", "..", "lib", "wlbud","wlgrammar.treetop"))
      @parser = WLBud::WebdamLogGrammarParser.new
      IO.readlines('test_program_2',';').each do |line|
        output = @parser.parse(line)
        if output
          assert_kind_of(WLBud::WLVocabulary, output, "output should be an object of class WLBud::WLVocabulary instead of #{output.class}")
        end
      end
      
    ensure
      File.delete('test_program_2') if File.exists?('test_program_2')
    end
  end # test_load_treetop_grammar
end # class TcParseProgram


# Test variables in rules and rule rewriting in rule_mapping
class TcRulesWLVocabulary < Test::Unit::TestCase
  include MixinTcWlTest

  # Test variables in atom fields
  def test_variables_atoms_rules
    prog = <<-EOF
peer sigmod_peer = localhost:10000;
collection ext persistent contact@local(username*, peerlocation*, online*, email*);
rule contact@local($username, $peerlocation, $online, "asnwer@email.com"):-contact@sigmod_peer($username, $peerlocation, $online, "email@email.com");
end
    EOF
  
    File.open('test_program_2',"w"){ |file| file.write prog}
    program = nil
    program = WLBud::WLProgram.new(
      'the_peername',
      'test_program_2',
      'localhost',
      '11111',
      {:debug => true} )
    assert_equal 1, program.rule_mapping.size
    local = "rule contact_at_the_peername($username, $peerlocation, $online, \"asnwer@email.com\") :- contact_at_sigmod_peer($username, $peerlocation, $online, \"email@email.com\");"
    delegation = "rule contact@the_peername($username, $peerlocation, $online, \"asnwer@email.com\") :- contact@sigmod_peer($username, $peerlocation, $online, \"email@email.com\");"
    assert_equal 1, program.rule_mapping.first.first, "one rule with index 1 should have been added"
    assert_equal local, program.rule_mapping.first[1].first.show_wdl_format

    #test rewriting of non local rule
    test_rule = program.rule_mapping.first[1].first
    assert_kind_of Fixnum, program.rule_mapping.first[0], "index of rule_mapping should be a Fixnum"
    assert_equal local, test_rule.show_wdl_format, "first element of the array in value of the first field of rule_mapping should be the oringinal rule"
    assert_equal 1, program.rule_mapping.size, "only one rule for now and no rewriting"
    program.rewrite_rule test_rule
    assert_equal local, program.rule_mapping.first[1].first.show_wdl_format, "first element of the array in value of the first field of rule_mapping should be the original rule"
    assert_equal delegation, program.rule_mapping.first[1][1], "second element of the array in value of the first field of rule_mapping should be the delegation"

    values = program.rule_mapping.values
    assert_equal 2, values[0].size
    assert_kind_of(WLBud::WLRule, values[0].first)
    assert_equal delegation, values[0][1]

    assert_equal 1, values[1].size
    assert_kind_of String, values[1].first
    assert_equal delegation, values[1].first

    assert_equal 4, program.rule_mapping[1].first.head.rfields.fields.length
    assert_equal 3, program.rule_mapping[1].first.head.rfields.variables.length    
  ensure
    File.delete('test_program_2') if File.exists?('test_program_2')
  end
  
  #
  def test_variables_relation_name_rules
    prog = <<-EOF
peer sigmod_peer = localhost:10000;
collection ext persistent contact@local(username*, peerlocation*, online*, email*, facebook*);
collection ext persistent picture@local(title*, owner*, _id*, image_url*);
collection ext persistent contact@local(username*, ip*, port*, online*, email*);
collection int query2@local(title*,contact*,id*,image_url*);
rule contact@local($username, $peerlocation, $online, $email, none):-contact@sigmod_peer($username, $peerlocation, $online, $email, none);
rule query2@local($title, $contact, $id, $image_url):- contact@local($contact, $_, $_, $_, $_),picture@$contact($title, $contact, $id, $image_url);
    EOF
    File.open('test_variables_relation_name_rules',"w"){ |file| file.write prog }
    program = nil
    program = WLBud::WLProgram.new(
      'the_peername',
      'test_variables_relation_name_rules',
      'localhost',
      '11111',
      {:debug => true})
    
  ensure
    File.delete('test_variables_relation_name_rules') if File.exists?('test_variables_relation_name_rules')
  end
end

