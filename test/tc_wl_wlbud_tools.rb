# ####License####
 #  File name tc_wl_tools.rb
 #  Copyright © by INRIA
 # 
 #  Contributors : Webdam Team <webdam.inria.fr>
 #       Emilien Antoine <emilien[dot]antoine[@]inria[dot]fr>
 # 
 #   WebdamLog - Jul 10, 2012
 # 
 #   Encoding - UTF-8
# ####License####
$:.unshift File.dirname(__FILE__)
require 'header_test'

class TcWlTools < Test::Unit::TestCase

  # Test tool group arrays by given field
  # === Scenario
  # given an array of array and a field f on which to order by
  # === Assert
  # the hash produced have the field f in key and an array of the previous array
  # minus the key field with this field value as key
  #
  def test_1_grouped_by_field
    a = old_a = [ ["un", "deux", "cle", "trois"],
    ["uno", "dos", "cle", "tres"],
    ["un", "deux", "autre clex", "trois"] ]
    b = WLTools.merge_multivaluehash_grouped_by_field(a,2)

    exp_res = {"cle"=>[["un", "deux", "trois"], ["uno", "dos", "tres"]],  "autre clex"=>[["un", "deux", "trois"]]}
    assert_equal exp_res, b
    assert_equal old_a, a
  end

  # Test tool group arrays by given field
  # === Scenario
  # given an array of array of size 2 and a field f on which to order by
  # === Assert
  # the hash produced have the field f in key and an array of the previous array
  # minus the key field with this field value as key
  #
  def test_2_grouped_by_field_one_value_left
    a = old_a = [ ["cle", "trois"],
    ["cle", "tres"],
    ["autre clex", "trois"] ]
    b = WLTools.merge_multivaluehash_grouped_by_field(a,0)

    exp_res = {"cle"=>["trois", "tres"],  "autre clex"=>["trois"]}
    assert_equal exp_res, b
    assert_equal old_a, a
  end

  # Test tool group arrays by given field two time in a row with data as there
  # are in sbuffer
  # === Scenario
  # given an array of array representing the content of sbuffer
  # === Assert
  # applying two time the group_by give the hash of hash of tab wanted
  #
  def test_3_grouped_by_field_nested
    sbuffer = [
      ["localhost:11112", "other_at_p2", ["3", "23"]],
      ["localhost:11112", "join_at_p2", ["3", "23"]],
      ["localhost:11112", "join_at_p2", ["4", "24"]],
      ["localhost:11113", "join_at_p3", ["5", "25"]],
      ["localhost:11113", "join_at_p3", ["27", "127"]]
      ]
    sb_by_dest = WLTools.merge_multivaluehash_grouped_by_field(sbuffer,0)
    assert_equal(
      {"localhost:11113"=>[
          ["join_at_p3", ["5", "25"]], ["join_at_p3", ["27", "127"]]
        ],
      "localhost:11112"=>[
        ["other_at_p2", ["3", "23"]], ["join_at_p2", ["3", "23"]], ["join_at_p2", ["4", "24"]]
        ]
    },
      sb_by_dest)

    sb_by_rel = {}
    sb_by_dest.each_pair do |k, v|
      sb_by_rel[k] = WLTools::merge_multivaluehash_grouped_by_field(v,0)
    end
    assert_equal({"localhost:11112"=>{"join_at_p2"=>[["3", "23"], ["4", "24"]], "other_at_p2"=>[["3", "23"]]}, "localhost:11113"=>{"join_at_p3"=>[["5", "25"], ["27", "127"]]}},
    sb_by_rel)
  end

  # Test tool group arrays by given field two time in a row with data as there
  # are in sbuffer with only one field for each tuple
  # === Scenario
  # given an array of array representing the content of sbuffer
  # === Assert
  # applying two time the group_by give the hash of hash of tab wanted
  #
  def test_4_grouped_by_field_nested_one_value_left
    sbuffer = [
      ["localhost:11112", "other_at_p2", ["3"]],
      ["localhost:11112", "join_at_p2", ["3"]],
      ["localhost:11112", "join_at_p2", ["4"]],
      ["localhost:11113", "join_at_p3", ["5"]],
      ["localhost:11113", "join_at_p3", ["27"]]
      ]
    sb_by_dest = WLTools.merge_multivaluehash_grouped_by_field(sbuffer,0)
    assert_equal({"localhost:11113"=>[["join_at_p3", ["5"]], ["join_at_p3", ["27"]]], "localhost:11112"=>[["other_at_p2", ["3"]], ["join_at_p2", ["3"]], ["join_at_p2", ["4"]]]},
      sb_by_dest)

    sb_by_rel = {}
    sb_by_dest.each_pair do |k, v|
      sb_by_rel[k] = WLTools::merge_multivaluehash_grouped_by_field(v,0)
    end
    assert_equal({"localhost:11112"=>{"other_at_p2"=>[["3"]], "join_at_p2"=>[["3"], ["4"]]}, "localhost:11113"=>{"join_at_p3"=>[["5"], ["27"]]}},
    sb_by_rel)
  end
end
