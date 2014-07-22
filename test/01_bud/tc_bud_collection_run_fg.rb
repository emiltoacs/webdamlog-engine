$:.unshift File.dirname(__FILE__)
require_relative '../header_test'

class TcBudCollectionRunFg < Test::Unit::TestCase
  include MixinTcWlTest
  
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
        [true] if t.k1 == 2
      end
    end
  end
  def test_halt_builtin_scratch_run_fg
    program = TestHaltBuiltinScratchRunFg.new

    program.run_fg

    assert_equal([[ 0 ],[ 1 ],[ 2 ],[ 3 ]], program.tbl1.to_a.sort)
    assert_equal([[ true ]], program.halt.to_a.sort)

    assert_equal false, program.instance_variable_get(:@bud_started)
    assert_equal false, program.running_async
  end
  
end
