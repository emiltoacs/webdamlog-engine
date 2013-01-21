# ####License####
#  File name tc_bud_delete_fact.rb
#  Copyright © by INRIA
# 
#  Contributors : Webdam Team <webdam.inria.fr>
#       Emilien Antoine <emilien[dot]antoine[@]inria[dot]fr>
# 
#   WebdamLog - Aug 6, 2012
# 
#   Encoding - UTF-8
# ####License####
$:.unshift File.dirname(__FILE__)
require 'header_test'

class TcBudDeleteFact < Test::Unit::TestCase

  module ProgForTest
    state {
      table :childOf , [:child, :father, :mother]
      scratch :descendant, [:child, :parent]       #intensional descendant(parent,child)
      table :sibling, [:bro1, :bro2]
      scratch :scratchsibling, [:bro1, :bro2]
    }
    bootstrap {
      childOf <= [["E","F","M"],["e","F","M"]] #E is a child with father F and mother G
    }
    bloom :rules do
      #Sibling rule
      sibling <= (childOf*childOf).pairs(:father => :father,:mother => :mother){|s1,s2| [s1.child,s2.child] if s1!=s2}
      scratchsibling <= (childOf*childOf).pairs(:father => :father,:mother => :mother){|s1,s2| [s1.child,s2.child] if s1!=s2}
      descendant <= childOf { |a| [a.child, a.father] }
      descendant <= childOf { |a| [a.child, a.mother] }
      descendant <= (descendant*descendant).pairs(:parent => :child) {|a1,a2| [a1.child, a2.parent]}
    end
  end

  class RunTestProg
    include Bud
    include ProgForTest
  end

  # Test remove operation in Bud thanks to pending_delete method
  # === Scenario
  # a scratch is dependent of a table that is updated
  # scratch descendant :- table childOf
  # === Assert
  # Content of descendant is updated as soon as a change is done in childOf
  #
  def test_1_remove_from_table_prop_to_scratch
    # Initialization
    prog = RunTestProg.new()
    prog.tick
    assert_equal 2, prog.childOf.to_a.length
    assert_equal [["E", "F", "M"], ["e", "F", "M"]], prog.childOf.to_a.sort
    assert_equal 4, prog.descendant.to_a.length
    assert_equal [["E","F"],["E","M"],["e","F"],["e","M"]], prog.descendant.to_a.sort

    # This append new fact to the collection childOf
    prog.childOf <= [["F","FF","MF"], ["M","FM","MM"]]
    prog.tick
    assert_equal [["E", "F"],["E", "FF"],["E", "FM"],["E", "M"],["E", "MF"],["E", "MM"],["F", "FF"],
      ["F", "MF"],["M", "FM"],["M", "MM"],["e", "F"],["e", "FF"],["e", "FM"],["e", "M"],["e", "MF"],["e", "MM"]],
      prog.descendant.to_a.sort

    #Remove
    #to_delete in bud is private
    prog.childOf.pending_delete [["M","FM","MM"]]
    prog.tick
    assert_equal [["E", "F"],
      ["E", "FF"],
      ["E", "M"],
      ["E", "MF"],
      ["F", "FF"],
      ["F", "MF"],
      ["e", "F"],
      ["e", "FF"],
      ["e", "M"],
      ["e", "MF"]],
      prog.descendant.to_a.sort
  ensure
    if EventMachine::reactor_running?
      prog.stop(true) # for the last I also stop EM to be clean
    end
  end

  # Test remove operation in Bud thanks to pending_delete method
  # === Scenario
  # a table is dependent of another table that is updated table sibling :- table
  # childOf
  # === Assert
  # Content of sibling is not updated with removed facts from childOf: No
  # deletion propagation to tables.
  #
  def test_2_remove_from_table_prop_to_table
    prog = RunTestProg.new()
    prog.tick
    assert_equal 2, prog.childOf.to_a.length
    assert_equal [["E", "F", "M"], ["e", "F", "M"]], prog.childOf.to_a.sort
    assert_equal 2, prog.sibling.to_a.length
    assert_equal [["E", "e"], ["e", "E"]], prog.sibling.to_a.sort

    # This append new fact to the collection childOf
    prog.childOf <= [["E2", "F", "M"], ["e2", "F", "M"]]
    prog.tick
    assert_equal 4, prog.childOf.to_a.length
    assert_equal [["E", "F", "M"], ["E2", "F", "M"], ["e", "F", "M"], ["e2", "F", "M"]], prog.childOf.to_a.sort
    assert_equal 12, prog.sibling.to_a.length
    assert_equal [["E", "E2"], ["E", "e"], ["E", "e2"], ["E2", "E"], ["E2", "e"], ["E2", "e2"], ["e", "E"], ["e", "E2"], ["e", "e2"], ["e2", "E"], ["e2", "E2"], ["e2", "e"]], prog.sibling.to_a.sort

    # This remove fact from the collection childOf but doesn't propagate to sibling
    prog.childOf.pending_delete [["E", "F", "M"]]
    prog.tick
    assert_equal 3, prog.childOf.to_a.length
    assert_equal [["E2", "F", "M"], ["e", "F", "M"], ["e2", "F", "M"]], prog.childOf.to_a.sort
    assert_equal 12, prog.sibling.to_a.length
    assert_equal [["E", "E2"], ["E", "e"], ["E", "e2"], ["E2", "E"], ["E2", "e"], ["E2", "e2"], ["e", "E"], ["e", "E2"], ["e", "e2"], ["e2", "E"], ["e2", "E2"], ["e2", "e"]], prog.sibling.to_a.sort
    assert_equal 6, prog.scratchsibling.to_a.length
    assert_equal [["E2", "e"], ["E2", "e2"], ["e", "E2"], ["e", "e2"], ["e2", "E2"], ["e2", "e"]], prog.scratchsibling.to_a.sort
    ensure
    if EventMachine::reactor_running?
      prog.stop(true) # for the last I also stop EM to be clean
    end
  end




end



