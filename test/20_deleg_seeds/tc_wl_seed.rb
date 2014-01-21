$:.unshift File.dirname(__FILE__)
require_relative '../header_test'
require_relative '../../lib/webdamlog_runner'

require 'test/unit'

# Test program with seeds ie. relation or peer name variables


# Test the method in program to rewrite unbound rules into seed rule
#
# The rule used here is a very long one to test many case of bounding variables
# and generating intermediary relation
#
# rule local1@test_seed($h1,$h2,$h3) :- local2@test_seed($l1,$h1),
# local3@test_seed($l1,$s1), local4@test_seed($s2,$l3), $s1@test_seed($h2,$h3),
# local4@test_seed($_, $s2);
class TcWlSeedRewriteUnboundRule < Test::Unit::TestCase
  include MixinTcWlTest

  def setup
    @pg = <<-EOF
peer test_seed=localhost:11110;
peer p1=localhost:11111;
peer p2=localhost:11112;
peer p3=localhost:11113;
collection ext per local1@test_seed(atom1*,atom2*,atom3*);
collection ext per local2@test_seed(atom1*,atom2*);
collection ext per local3@test_seed(atom1*,atom2*);
collection ext per local4@test_seed(atom1*,atom2*);
collection ext persistent relname1@test_seed(atom1*,atom2*);
collection ext persistent relname2@test_seed(atom1*,atom2*);
fact local2@test_seed("flocal1","flocalhead1");
fact local2@test_seed("flocal2","flocalhead2");
fact local3@test_seed("flocal1","relname1");
fact local3@test_seed("flocal1","relname2");
fact local4@test_seed("flocal3","useless1");
fact local4@test_seed("flocal3","useless2");
fact local4@test_seed("flocal3","useless1");
fact local4@test_seed("flocal3","useless2");
fact local4@test_seed("useless3","flocal3");
fact local4@test_seed("useless4","flocal4");
fact relname1@test_seed("relname1_1_1","relname1_1_2");
fact relname1@test_seed("relname1_2_1","relname1_2_2");
fact relname2@test_seed("relname2_1_1","relname2_1_2");
fact relname2@test_seed("relname2_2_1","relname2_2_2");
end
    EOF
    @username = "test_seed"
    @port = "11110"
    @pg_file = "test_seed_install_local"
    File.open(@pg_file,"w"){ |file| file.write @pg }
  end

  def teardown
    File.delete(@pg_file) if File.exists?(@pg_file)
    ObjectSpace.each_object(WLRunner) do |obj|
      clean_rule_dir obj.rule_dir
      obj.delete
    end
    ObjectSpace.garbage_collect
  end

  # test the rewrite_unbound_rules method in wl_program
  def test_seed_rewrite_unbound_rules
    pg = WLBud::WLProgram.new(@username, @pg_file, 'localhost', @ip)

    test_string =
      "rule local1@test_seed($h1,$h2,$h3) :- local2@test_seed($l1,$h1),local3@test_seed($l1,$s1),local4@test_seed($s2,$l3),$s1@test_seed($h2,$h3),local4@test_seed($_,$s2);"
    result = pg.parse test_string, true

    assert( ! pg.bound_n_local?(result), "this rule is not bounded")

    assert_equal(
      "rule local1@test_seed($h1, $h2, $h3) :- local2@test_seed($l1, $h1), local3@test_seed($l1, $s1), local4@test_seed($s2, $l3), $s1@test_seed($h2, $h3), local4@test_seed($_, $s2);",
      result.show_wdl_format)

    # the method we want to test
    pg.rewrite_rule result

    # test the split in two parts
    assert_equal ["local2@test_seed($l1, $h1)","local3@test_seed($l1, $s1)","local4@test_seed($s2, $l3)"],
      result.bound.map { |e| e.show_wdl_format }
    assert_equal ["$s1@test_seed($h2, $h3)", "local4@test_seed($_, $s2)"],
      result.unbound.map { |e| e.show_wdl_format }
    assert_equal "local1@test_seed($h1, $h2, $h3)", result.head.show_wdl_format

    new_dec = pg.flush_new_local_declaration

    # test the new seed relation to declare
    assert_equal "intermediary seed_from_test_seed_1_1@test_seed( seed_from_test_seed_1_1_h1_0*,seed_from_test_seed_1_1_s1_1*,seed_from_test_seed_1_1_s2_2* ) ;",
      new_dec.first.show_wdl_format

    arr_new_rul = pg.flush_new_seed_rule_to_install
    new_rul = arr_new_rul.first.first
    new_ato = arr_new_rul.first[1]
    new_ste = arr_new_rul.first[2]

    # test the new seed rule installed locally
    assert_equal "rule seed_from_test_seed_1_1@test_seed($h1, $s1, $s2) :- local2@test_seed($l1, $h1), local3@test_seed($l1, $s1), local4@test_seed($s2, $l3);",
      new_rul.show_wdl_format

    assert_equal "seed_from_test_seed_1_1@test_seed($h1,$s1,$s2)", new_ato

    assert_equal "rule local1@test_seed($h1, $h2, $h3):-seed_from_test_seed_1_1@test_seed($h1,$s1,$s2),$s1@test_seed($h2,$h3),local4@test_seed($_,$s2);",
      new_ste
  end


  # test the install method when seeds are passed to it
  def test_seed_install_rule_with_seed
    begin
      runner = WLRunner.create @username, @pg_file, @port
      test_string =
        "rule local1@test_seed($h1,$h2,$h3) :- local2@test_seed($l1,$h1),local3@test_seed($l1,$s1),local4@test_seed($s2,$l3),$s1@test_seed($h2,$h3),local4@test_seed($_,$s2);"
      runner.tick
      runner.update_add_rule(test_string)

      assert_equal 1, runner.seed_to_sprout.size
      seed_arr = runner.seed_to_sprout.first
      assert_equal 5, seed_arr.size
      assert_equal "rule seed_from_test_seed_1_1@test_seed($h1, $s1, $s2) :- local2@test_seed($l1, $h1), local3@test_seed($l1, $s1), local4@test_seed($s2, $l3);",
        seed_arr[0].show_wdl_format, "expected a local rule to use as a seeder"
      assert_equal "seed_from_test_seed_1_1@test_seed($h1,$s1,$s2)", seed_arr[1], "intermediatry relation expected"
      assert_equal "rule local1@test_seed($h1, $h2, $h3):-seed_from_test_seed_1_1@test_seed($h1,$s1,$s2),$s1@test_seed($h2,$h3),local4@test_seed($_,$s2);",
        seed_arr[2], "seed template expected"
      assert_equal "rule local1@test_seed($h1, $h2, $h3) :- local2@test_seed($l1, $h1), local3@test_seed($l1, $s1), local4@test_seed($s2, $l3), $s1@test_seed($h2, $h3), local4@test_seed($_, $s2);",
        seed_arr[3].show_wdl_format, "original rule expected"
      assert_equal "seed_from_test_seed_1_1_at_test_seed", seed_arr[4], "bud relation name of intermediary table"
    ensure
      runner.stop
    end
  end

  # test the method seed_sprout test the method seed_sprout
  def test_seed_sprout
    begin
      runner = WLRunner.create @username, @pg_file, @port
      test_string = "rule local1@test_seed($h1,$h2,$h3) :- local2@test_seed($l1,$h1),local3@test_seed($l1,$s1),local4@test_seed($s2,$l3),$s1@test_seed($h2,$h3),local4@test_seed($_,$s2);"
      runner.tick

      assert runner.sprout_rules.empty?
      runner.update_add_rule(test_string)

      assert runner.sprout_rules.empty?

      assert_equal 1,runner.t_rules.length, "only the original rule is installed"
      runner.tick

      assert_equal [
        "rule local1@test_seed(flocalhead1, $h2, $h3) :- seed_from_test_seed_1_1@test_seed(flocalhead1, relname1, flocal3), relname1@test_seed($h2, $h3), local4@test_seed($_, flocal3);",
        "rule local1@test_seed(flocalhead1, $h2, $h3) :- seed_from_test_seed_1_1@test_seed(flocalhead1, relname2, flocal3), relname2@test_seed($h2, $h3), local4@test_seed($_, flocal3);",
        "rule local1@test_seed(flocalhead1, $h2, $h3) :- seed_from_test_seed_1_1@test_seed(flocalhead1, relname1, useless3), relname1@test_seed($h2, $h3), local4@test_seed($_, useless3);",
        "rule local1@test_seed(flocalhead1, $h2, $h3) :- seed_from_test_seed_1_1@test_seed(flocalhead1, relname2, useless3), relname2@test_seed($h2, $h3), local4@test_seed($_, useless3);",
        "rule local1@test_seed(flocalhead1, $h2, $h3) :- seed_from_test_seed_1_1@test_seed(flocalhead1, relname1, useless4), relname1@test_seed($h2, $h3), local4@test_seed($_, useless4);",
        "rule local1@test_seed(flocalhead1, $h2, $h3) :- seed_from_test_seed_1_1@test_seed(flocalhead1, relname2, useless4), relname2@test_seed($h2, $h3), local4@test_seed($_, useless4);"],
        runner.sprout_rules.keys
      assert_equal 7,runner.t_rules.length, "2 rules srpout from seeds must be installed"

      assert_equal({[:bud_obj, :rule_id]=>[:lhs, :op, :src, :orig_src, :unsafe_funcs_called]},
        runner.t_rules.schema,
        "check the schema of builtins tables of rules for introspection")

      runner.t_rules.pro { |t| assert_equal(t.src, t.orig_src, "rules has been reparsed by bud after webdamlog add them") }

      assert_equal [["seed_from_test_seed_1_1_at_test_seed <= (((local2_at_test_seed * local3_at_test_seed) * local4_at_test_seed).combos(local2_at_test_seed.atom1 => (local3_at_test_seed.atom1)) do |atom0, atom1, atom2|\n  [atom0[1], atom1[1], atom2[0]]\nend)"],
        ["local1_at_test_seed <= (((seed_from_test_seed_1_1_at_test_seed * relname1_at_test_seed) * local4_at_test_seed).combos do |atom0, atom1, atom2|\n  if (atom0[0] == \"flocalhead1\") and ((atom0[1] == \"relname1\") and ((atom0[2] == \"flocal3\") and (atom2[1] == \"flocal3\"))) then\n    [\"flocalhead1\", atom1[0], atom1[1]]\n  end\nend)"],
        ["local1_at_test_seed <= (((seed_from_test_seed_1_1_at_test_seed * relname2_at_test_seed) * local4_at_test_seed).combos do |atom0, atom1, atom2|\n  if (atom0[0] == \"flocalhead1\") and ((atom0[1] == \"relname2\") and ((atom0[2] == \"flocal3\") and (atom2[1] == \"flocal3\"))) then\n    [\"flocalhead1\", atom1[0], atom1[1]]\n  end\nend)"],
        ["local1_at_test_seed <= (((seed_from_test_seed_1_1_at_test_seed * relname1_at_test_seed) * local4_at_test_seed).combos do |atom0, atom1, atom2|\n  if (atom0[0] == \"flocalhead1\") and ((atom0[1] == \"relname1\") and ((atom0[2] == \"useless3\") and (atom2[1] == \"useless3\"))) then\n    [\"flocalhead1\", atom1[0], atom1[1]]\n  end\nend)"],
        ["local1_at_test_seed <= (((seed_from_test_seed_1_1_at_test_seed * relname2_at_test_seed) * local4_at_test_seed).combos do |atom0, atom1, atom2|\n  if (atom0[0] == \"flocalhead1\") and ((atom0[1] == \"relname2\") and ((atom0[2] == \"useless3\") and (atom2[1] == \"useless3\"))) then\n    [\"flocalhead1\", atom1[0], atom1[1]]\n  end\nend)"],
        ["local1_at_test_seed <= (((seed_from_test_seed_1_1_at_test_seed * relname1_at_test_seed) * local4_at_test_seed).combos do |atom0, atom1, atom2|\n  if (atom0[0] == \"flocalhead1\") and ((atom0[1] == \"relname1\") and ((atom0[2] == \"useless4\") and (atom2[1] == \"useless4\"))) then\n    [\"flocalhead1\", atom1[0], atom1[1]]\n  end\nend)"],
        ["local1_at_test_seed <= (((seed_from_test_seed_1_1_at_test_seed * relname2_at_test_seed) * local4_at_test_seed).combos do |atom0, atom1, atom2|\n  if (atom0[0] == \"flocalhead1\") and ((atom0[1] == \"relname2\") and ((atom0[2] == \"useless4\") and (atom2[1] == \"useless4\"))) then\n    [\"flocalhead1\", atom1[0], atom1[1]]\n  end\nend)"]],
        runner.t_rules.pro { |t| [t.src] },
        "the bud program running is wrong"

      assert_equal([["flocalhead1", "relname1", "flocal3"],
          ["flocalhead1", "relname2", "flocal3"],
          ["flocalhead1", "relname1", "useless3"],
          ["flocalhead1", "relname2", "useless3"],
          ["flocalhead1", "relname1", "useless4"],
          ["flocalhead1", "relname2", "useless4"]],
        runner.tables[:seed_from_test_seed_1_1_at_test_seed].pro { |t| t.to_a },
        "intermediary relation created should have some tuples")
      
      assert_equal [["flocalhead1", "relname1_1_1", "relname1_1_2"],
        ["flocalhead1", "relname1_2_1", "relname1_2_2"],
        ["flocalhead1", "relname2_1_1", "relname2_1_2"],
        ["flocalhead1", "relname2_2_1", "relname2_2_2"]],
        runner.tables[:local1_at_test_seed].pro { |t| t.to_a }
    ensure
      runner.stop
    end
  end
end