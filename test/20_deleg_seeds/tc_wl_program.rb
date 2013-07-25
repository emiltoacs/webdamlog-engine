$:.unshift File.dirname(__FILE__)
require 'header_test'
require_relative '../../lib/webdamlog_runner'

require 'test/unit'

class TcWlProgram < Test::Unit::TestCase

  # test the method split-rule in wlprogram that parse and divide the rule according to local atoms and variables in relation or peer name
  def test_split_rules

    Treetop.load(File.join(File.dirname(__FILE__), "..", "..", "lib", "wlbud","wlgrammar.treetop"))
    @@parser = WLBud::WebdamLogGrammarParser.new

    # create a new program with just another peer declaration
    prog = <<-EOF
peer other = localhost:10000;
    EOF
    File.open('test_split_rules',"w"){ |file| file.write prog }
    program = WLBud::WLProgram.new(
      'the_peername',
      'test_split_rules',
      'localhost',
      '11111',
      {:debug => true} )

    # each case of distribution

    # check loading of basic local rule
    output = @@parser.parse('rule contact@local($username):-friend@local($username);')
    assert_not_nil output, "#{@@parser.failure_reason}"
    assert_kind_of WLBud::WLVocabulary, output
    rule = output.get_inst
    assert_kind_of WLBud::WLRule, rule
    assert_equal nil, rule.split
    assert_equal [], rule.bound
    assert_equal [], rule.unbound
    # check basic local rules aren't split
    assert_equal false, program.send(:split_rule, rule)
    assert_equal ["friend_at_local($username)"], rule.bound.map { |item| item.show_wdl_format }
    assert_equal [], rule.unbound.map { |item| item.show_wdl_format }

    # check delegation are split
    output = @@parser.parse('rule contact@local($username):-friend@local($username),friend@other($username);')
    rule = output.get_inst
    assert_equal true, program.send(:split_rule, rule)
    assert_equal ["friend_at_local($username)"], rule.bound.map { |item| item.show_wdl_format }
    assert_equal ["friend_at_other($username)"], rule.unbound.map { |item| item.show_wdl_format }

    # check full delegation are split
    output = @@parser.parse('rule contact@local($username):-friend@other($username);')
    rule = output.get_inst
    assert_equal true, program.send(:split_rule, rule)
    assert_equal [], rule.bound.map { |item| item.show_wdl_format }
    assert_equal ["friend_at_other($username)"], rule.unbound.map { |item| item.show_wdl_format }

    # check non-local head are not split
    output = @@parser.parse('rule contact@other($username):-friend@local($username),family@local($username);')
    rule = output.get_inst
    assert_equal false, program.send(:split_rule, rule)
    assert_equal ["friend_at_local($username)", "family_at_local($username)"], rule.bound.map { |item| item.show_wdl_format }
    assert_equal [], rule.unbound.map { |item| item.show_wdl_format }

    # each case of variable

    # variable in the middle of the body
    output = @@parser.parse('rule contact@other($family):-friend@local($username),family@$username($family);')
    rule = output.get_inst
    assert_equal true, program.send(:split_rule, rule)
    assert_equal true, rule.seed
    assert_equal 1, rule.seed_pos
    assert_equal ["friend_at_local($username)"], rule.bound.map { |item| item.show_wdl_format }
    assert_equal ["family_at_$username($family)"], rule.unbound.map { |item| item.show_wdl_format }

    # multiple variable in the body detect the first one
    output = @@parser.parse('rule contact@other($family):-friend@$username($username),family@$username($family);')
    rule = output.get_inst
    assert_equal true, program.send(:split_rule, rule)
    assert_equal true, rule.seed
    assert_equal 0, rule.seed_pos
    assert_equal [], rule.bound.map { |item| item.show_wdl_format }
    assert_equal ["friend_at_$username($username)", "family_at_$username($family)"], rule.unbound.map { |item| item.show_wdl_format }

    # variable in the head
    output = @@parser.parse('rule contact@$username($family):-friend@local($username),family@local($family);')
    rule = output.get_inst
    assert_equal true, program.send(:split_rule, rule)
    assert_equal true, rule.seed
    assert_equal -1, rule.seed_pos
    assert_equal ["friend_at_local($username)", "family_at_local($family)"], rule.bound.map { |item| item.show_wdl_format }
    assert_equal [], rule.unbound.map { |item| item.show_wdl_format }

    # mix of seed and non-local

    # with non-local first, seed should not be detected
    output = @@parser.parse('rule contact@$username($family):-friend@local($username),family@other($family);')
    rule = output.get_inst
    assert_equal true, program.send(:split_rule, rule)
    assert_equal false, rule.seed
    assert_equal nil, rule.seed_pos
    assert_equal ["friend_at_local($username)"], rule.bound.map { |item| item.show_wdl_format }
    assert_equal ["family_at_other($family)"], rule.unbound.map { |item| item.show_wdl_format }

    # with seed first non-local should not be detected
    output = @@parser.parse('rule contact@$username($family):-friend@local($username),family@$username($family),friend@local($username);')
    rule = output.get_inst
    assert_equal true, program.send(:split_rule, rule)
    assert_equal true, rule.seed
    assert_equal 1, rule.seed_pos
    assert_equal ["friend_at_local($username)"], rule.bound.map { |item| item.show_wdl_format }
    assert_equal ["family_at_$username($family)", "friend_at_local($username)"], rule.unbound.map { |item| item.show_wdl_format }
    
  ensure
    File.delete('test_split_rules') if File.exists?('test_split_rules')
  end

end
