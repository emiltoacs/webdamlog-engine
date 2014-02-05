# ####License####
#  File name tc_bud_collection.rb
#  Copyright © by INRIA
#
#  Contributors : Webdam Team <webdam.inria.fr>
#       Emilien Antoine <emilien[dot]antoine[@]inria[dot]fr>
#
#   WebdamLog - Aug 14, 2012
#
#   Encoding - UTF-8
# ####License####
$:.unshift File.dirname(__FILE__)
require_relative '../header_test'

# To test the behavior of the bud collection in the spirit of their test
# https://github.com/bloom-lang/bud/blob/master/test/tc_collections.rb
#
class TcBudCollection < Test::Unit::TestCase
  include MixinTcWlTest

  # test collection of arity zero
  class Arity0Collection
    include Bud
    state do
      scratch :scrtch, []
      table :tbl, []
    end
    bootstrap do
      tbl <= []
      scrtch <= []
    end
    # you cannot write rule with arity 0 collection in the head
    bloom do
    end
  end
  def test_arity_0_collection
    program = Arity0Collection.new
    program.tick
    assert_equal(0, program.scrtch.length)
    assert_equal(0, program.tbl.length)
  end

  # Check that scratch with deferred operators works well for facts
  #
  # add constant fact via deferred into the scratch makes it persist across
  # timestamps
  class ScratchDeferredOpAddFact
    include Bud
    state do
      scratch :scrtch, [:k1, :k2] => [:v1, :v2]
      scratch :scrtch2, [:k1, :k2]
      table :tbl, [:k1, :k2] => [:v1, :v2]
    end
    bootstrap do
      scrtch <= [['a', 'b', 1, 2],['a', 'c', 3, 4]]
      scrtch2 <= [['a', 'b']]
      tbl <= [['a', 'b', 1, 2],['z', 'y', 9, 8]]
    end
    bloom do
      scrtch <+ [['c', 'd', 5, 6]] #re-derive this fact for scrtch
      tbl <+ [['c', 'd', 5, 6]]
      tbl <- [['a', 'b', 1, 2]]
    end
  end
  def test_scratch_deferred_op_add_fact
    program = ScratchDeferredOpAddFact.new
    program.tick
    assert_equal(2, program.scrtch.length)
    assert_equal [['a', 'b', 1, 2],['a', 'c', 3, 4]], program.scrtch.to_a.sort
    assert_equal(1, program.scrtch2.length)
    assert_equal [['a', 'b']], program.scrtch2.to_a.sort
    assert_equal(2, program.scrtch.length)
    assert_equal [['a', 'b', 1, 2],['z', 'y', 9, 8]], program.tbl.to_a.sort
    program.tick
    assert_equal(1, program.scrtch.length)
    assert_equal [['c', 'd', 5, 6]], program.scrtch.to_a.sort
    assert_equal [], program.scrtch2.to_a.sort
    assert_equal [['c', 'd', 5, 6],['z', 'y', 9, 8]], program.tbl.to_a.sort
    program.tick
    assert_equal [['c', 'd', 5, 6]], program.scrtch.to_a.sort
    assert_equal [], program.scrtch2.to_a.sort
    assert_equal [['c', 'd', 5, 6],['z', 'y', 9, 8]], program.tbl.to_a.sort    
  end

  # Check how the internal buffers in collections reacts
  class InternalBuffer
    include Bud
    state do
      scratch :scrtch, [:k1] => [:v1, :v2]
      table :tbl, [:k1] => [:v1, :v2]
    end
    bootstrap do
      scrtch <= [['s1', 1, 2],['s2', 3, 4]]
      tbl <= [['t1', 1, 2],['t2', -1, -2]]
    end
    bloom do
    end
  end
  # Values inserted in tables with <= or <+ goes to delta but here there are no
  # rules hence the behavior is a bit strange
  def test_internal_buffer
    puts "=== test_internal_buffer BEGIN" if $test_verbose
    pg = InternalBuffer.new
    pg.tick
    assert_equal( [['s1', 1, 2],['s2', 3, 4]], pg.scrtch.to_a.sort)
    assert_equal( [['t1', 1, 2],['t2', -1, -2]], pg.tbl.to_a.sort)
    pg.tick
    assert_equal( [], pg.scrtch.to_a.sort)
    assert_equal( [['t1', 1, 2],['t2', -1, -2]], pg.tbl.to_a.sort)
    assert_equal( [['t1', 1, 2],['t2', -1, -2]], pg.tbl.delta.values.to_a.sort)
    assert_equal( [], pg.tbl.storage.values.to_a.sort)
    # pg.tbl <= [['t3',-3, -4]] # this now longer work on purpose since bud
    # 0.9.7
    pg.tbl <+ [['t4',-5, -6]]
    pg.tick
    assert_equal( [], pg.scrtch.to_a.sort)
    assert_equal( [['t1', 1, 2],['t2', -1, -2],['t4',-5, -6]], pg.tbl.delta.values.to_a.sort )
    assert_equal( [], pg.tbl.storage.values.to_a.sort)
    assert_equal( [['t1', 1, 2],['t2', -1, -2],['t4',-5, -6]], pg.tbl.to_a.sort )
    # pg.scrtch <= [['s3',-3, -4]] # this now longer work on purpose since bud
    # 0.9.7
    pg.scrtch <+ [['s4',-5, -6]]
    pg.tick
    assert_equal( [['t1', 1, 2],['t2', -1, -2],['t4',-5, -6]], pg.tbl.to_a.sort )
    assert_equal( [['t1', 1, 2],['t2', -1, -2],['t4',-5, -6]], pg.tbl.delta.values.to_a.sort )
    assert_equal( [['s4', -5, -6]], pg.scrtch.to_a.sort )
    assert_equal( [['s4', -5, -6]], pg.scrtch.delta.values.to_a.sort )
    assert_equal( [], pg.scrtch.storage.values.to_a.sort)
    puts "=== test_internal_buffer END" if $test_verbose
  end

  # Check that scratch with deferred operators works well for rules
  # XXX a scratch seems not updated correctly
  class ScratchDeferredOpRule
    include Bud
    state do
      scratch :scrtch, [:k1, :k2] => [:v1, :v2]
      table :tbl, [:k1, :k2] => [:v1, :v2]
      scratch :scrtch2, [:k1, :k2]
      scratch :scrtch3, [:k1, :k2]      
    end
    bootstrap do
      scrtch <= [['a', 'b', 1, 2],['a', 'c', 3, 4]]
      tbl <= [['a', 'b', 1, 2],['z', 'y', 9, 8]]
      scrtch2 <= [['m', 'n'],['o', 'p']]
      scrtch3 <= [['m', 'n'],['o', 'p']]      
    end
    bloom do
      scrtch2 <+ scrtch{ |t| [t[0],t[1]] }
      scrtch2 <+ tbl{ |t| [t[0],t[1]] }
      
      scrtch3 <+ scrtch{ |t| [t[0],t[1]] }
      scrtch3 <= tbl{ |t| [t[0],t[1]] }
    end
  end
  
  def test_scratch_deferred_op_rule
    program = ScratchDeferredOpRule.new
    program.tick
    # scratch has the content described in bootstrap 
    assert_equal( [['a', 'b', 1, 2],['a', 'c', 3, 4]], program.scrtch.to_a.sort)
    # table has the content described in bootstrap
    assert_equal( [['a', 'b', 1, 2],['z', 'y', 9, 8]], program.tbl.to_a.sort)
    # scratch received nothing at this tick since operators are deferred
    assert_equal( [['m', 'n'],['o', 'p']], program.scrtch2.to_a.sort)
    # scratch received instantaneously the content of tbl
    assert_equal( [['a', 'b'],['m', 'n'],['o', 'p'],['z', 'y']], program.scrtch3.to_a.sort)

    program.tick
    # scratch are emptied and no rules or pending fact for scrtch
    assert_equal( [], program.scrtch.to_a.sort)
    # tables are persistent so no changes till previous tick
    assert_equal( [['a', 'b', 1, 2],['z', 'y', 9, 8]], program.tbl.to_a.sort)
    # scrtch2 received the facts pending from previous tick
    assert_equal( [['a', 'b'],['a', 'c'],['z', 'y']], program.scrtch2.to_a.sort)
    # scrtch3 continue to receive the facts instantaneously from tbl and the pending facts from scratch at the previous step
    assert_equal( [['a', 'b'],['a', 'c'],['z', 'y']], program.scrtch3.to_a.sort)

    program.tick
    assert_equal( [], program.scrtch.to_a.sort)
    assert_equal( [['a', 'b', 1, 2],['z', 'y', 9, 8]], program.tbl.to_a.sort)
    # pending facts from tbl and nothing from scrtch since it was empty at previous tick
    assert_equal( [['a', 'b'],['z', 'y']], program.scrtch2.to_a.sort)
    # XXX the ['a', 'c'] fact seems to be too much
    assert_equal( [['a', 'b'],['a', 'c'],['z', 'y']], program.scrtch3.to_a.sort)
    program.tick
    program.tick
    program.tick
    program.tick
    assert_equal( [], program.scrtch.to_a.sort)
    assert_equal( [['a', 'b', 1, 2],['z', 'y', 9, 8]], program.tbl.to_a.sort)
    assert_equal( [['a', 'b'],['z', 'y']], program.scrtch2.to_a.sort)
    # XXX the ['a', 'c'] fact is still here
    assert_equal( [['a', 'b'],['a', 'c'],['z', 'y']], program.scrtch3.to_a.sort)
    program.tbl <+ [['d', 'e', 5, 6]]
    program.tick
    assert_equal( [], program.scrtch.to_a.sort)
    assert_equal( [['a', 'b', 1, 2],['d', 'e', 5, 6],['z', 'y', 9, 8]], program.tbl.to_a.sort)
    assert_equal( [['a', 'b'],['z', 'y']], program.scrtch2.to_a.sort)
    assert_equal( [['a', 'b'],['a', 'c'],['d', 'e'],['z', 'y']], program.scrtch3.to_a.sort)
    program.scrtch <+ [['f', 'g', 7, 8]]
    program.tick
    assert_equal( [['f', 'g', 7, 8]], program.scrtch.to_a.sort)
    assert_equal( [['a', 'b', 1, 2],['d', 'e', 5, 6],['z', 'y', 9, 8]], program.tbl.to_a.sort)
    assert_equal( [['a', 'b'],['d', 'e'],['z', 'y']], program.scrtch2.to_a.sort)
    assert_equal( [['a', 'b'],['a', 'c'],['d', 'e'],['z', 'y']], program.scrtch3.to_a.sort)
    program.tick
    assert_equal( [], program.scrtch.to_a.sort)
    assert_equal( [['a', 'b', 1, 2],['d', 'e', 5, 6],['z', 'y', 9, 8]], program.tbl.to_a.sort)
    assert_equal( [['a', 'b'],['d', 'e'],['f', 'g'],['z', 'y']], program.scrtch2.to_a.sort)
    # Now the fact ['a', 'c'] has disappeared, it requires that source table has to be invalidated
    assert_equal( [['a', 'b'],['d', 'e'],['f', 'g'],['z', 'y']], program.scrtch3.to_a.sort)
    program.tick
    assert_equal( [], program.scrtch.to_a.sort)
    assert_equal( [['a', 'b', 1, 2],['d', 'e', 5, 6],['z', 'y', 9, 8]], program.tbl.to_a.sort)
    assert_equal( [['a', 'b'],['d', 'e'],['z', 'y']], program.scrtch2.to_a.sort)
    # XXX Again we still have ['f', 'g'] that will be deleted next time an
    # invalidation will forces to recompute this scrtch3
    assert_equal( [['a', 'b'],['d', 'e'],['f', 'g'],['z', 'y']], program.scrtch3.to_a.sort)
  end

  # test collection of arity zero
  class TestHaltBuiltinScratch
    include Bud

    state do
      table :counter, [:k1,:k2]
      table :tbl1, [:k1]
    end
    bootstrap do
      counter <= [[0,1],[1,2],[2,3]]
      tbl1 <= [[0]]
    end
    bloom do
      tbl1 <+ (tbl1 * counter).combos(tbl1.k1 => counter.k1) do |t1,t2|
        [t2.k2]
      end
      halt <= tbl1 do |t|
        [:kill] if t.k1 == 2
      end
    end
  end
  
  def test_halt_builtin_scratch
    program = TestHaltBuiltinScratch.new
    program.tick
    assert_equal([[ 0 ]], program.tbl1.to_a.sort)
    program.tick
    assert_equal([[ 0 ],[ 1 ]], program.tbl1.to_a.sort)

    assert_equal true, program.instance_variable_get(:@bud_started)
    assert_equal false, program.running_async
    program.tick
    assert_equal([[ 0 ],[ 1 ],[ 2 ]], program.tbl1.to_a.sort)
    assert_equal([[ :kill ]], program.halt.to_a.sort)

    assert_equal false, program.instance_variable_get(:@bud_started)
    assert_equal false, program.running_async
  end



  class TestHaltBuiltinScratchRunFg
    include Bud

    state do
      table :counter, [:k1,:k2]
      table :tbl1, [:k1]
    end
    bootstrap do
      counter <= [[0,1],[1,2],[2,3]]
      tbl1 <= [[0]]
    end
    bloom do
      tbl1 <= (tbl1 * counter).combos(tbl1.k1 => counter.k1) do |t1,t2|
        [t2.k2]
      end
      halt <= tbl1 do |t|
        [:kill] if t.k1 == 2
      end
    end
  end

  def test_halt_builtin_scratch_run_fg
    program = TestHaltBuiltinScratchRunFg.new

    program.run_fg

    assert_equal([[ 0 ],[ 1 ],[ 2 ],[ 3 ]], program.tbl1.to_a.sort)
    assert_equal([[ :kill ]], program.halt.to_a.sort)

    assert_equal false, program.instance_variable_get(:@bud_started)
    assert_equal false, program.running_async
  end
end
