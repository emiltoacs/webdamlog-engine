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
require 'header_test'

# To test the behavior of the bud collection in the spirit of their test
# https://github.com/bloom-lang/bud/blob/master/test/tc_collections.rb
#
class TcBudCollection < Test::Unit::TestCase
  include MixinTcWlTest

  # Check that scratch with deferred operators works well for facts
  #
  # add constant fact via deferred into the scratch makes it persist across
  # timestamps
  #
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
  #
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
  #
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
    # pg.tbl <= [['t3',-3, -4]] # this now longer work on purpose since bud 0.9.7
    pg.tbl <+ [['t4',-5, -6]]
    pg.tick
    assert_equal( [], pg.scrtch.to_a.sort)
    assert_equal( [['t1', 1, 2],['t2', -1, -2],['t4',-5, -6]], pg.tbl.delta.values.to_a.sort )
    assert_equal( [], pg.tbl.storage.values.to_a.sort)
    assert_equal( [['t1', 1, 2],['t2', -1, -2],['t4',-5, -6]], pg.tbl.to_a.sort )
    # pg.scrtch <= [['s3',-3, -4]] # this now longer work on purpose since bud 0.9.7
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
  #
  # XXX: rule with defered operations on scratch seems buggy
  #
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
    assert_equal( [['a', 'b', 1, 2],['a', 'c', 3, 4]], program.scrtch.to_a.sort)
    assert_equal( [['a', 'b', 1, 2],['z', 'y', 9, 8]], program.tbl.to_a.sort)
    assert_equal( [['m', 'n'],['o', 'p']], program.scrtch2.to_a.sort)
    assert_equal( [['a', 'b'],['m', 'n'],['o', 'p'],['z', 'y']], program.scrtch3.to_a.sort)

    program.tick
    assert_equal( [], program.scrtch.to_a.sort)
    assert_equal( [['a', 'b', 1, 2],['z', 'y', 9, 8]], program.tbl.to_a.sort)
    assert_equal( [['a', 'b'],['a', 'c'],['z', 'y']], program.scrtch2.to_a.sort)
    assert_equal( [['a', 'b'],['a', 'c'],['z', 'y']], program.scrtch3.to_a.sort)

    program.tick
    assert_equal( [], program.scrtch.to_a.sort)
    assert_equal( [['a', 'b', 1, 2],['z', 'y', 9, 8]], program.tbl.to_a.sort)
    assert_equal( [['a', 'b'],['z', 'y']], program.scrtch2.to_a.sort)
    assert_equal( [['a', 'b'],['a', 'c'],['z', 'y']], program.scrtch3.to_a.sort)

    program.tick
    program.tick
    program.tick
    program.tick
    assert_equal( [], program.scrtch.to_a.sort)
    assert_equal( [['a', 'b', 1, 2],['z', 'y', 9, 8]], program.tbl.to_a.sort)
    assert_equal( [['a', 'b'],['z', 'y']], program.scrtch2.to_a.sort)
    assert_equal( [['a', 'b'],['a', 'c'],['z', 'y']], program.scrtch3.to_a.sort)
  end
end

