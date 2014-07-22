$:.unshift File.dirname(__FILE__)
require_relative '../header_test'

# Test file to check configuration of the project
#
class TcProjectConf < Test::Unit::TestCase
  include MixinTcWlTest

  # Test constant and variable accessible inside WLBud
  #
  def test_variable
    if $test_verbose
      puts "Content of load path in $: :\n "
      $:.each { |v| puts v }
      puts "\n List of global variables : \n"
      global_variables.each { |v| puts v + " " + eval("#{v}").to_s}
      puts "\n List of constant variables : \n"
      local_variables.each { |v| puts v + " " + eval("#{v}").to_s}
    end
    
    assert_not_nil WLBud::PATH_LIB,
      "need a path to the main directory of lib with WLBud"
    assert_not_nil WLBud::PATH_WLBUD,
      "need a path to the main directory of WLBud files"
    assert_not_nil WLBud::PATH_CONFIG,
      "need a path to the config file with config module for bud version"
    assert_not_nil WLBud::RULE_DIR_NAME,
      "should be able to access to the directory with rewritten rules"
    assert_not_nil WLBud::PATH_BUD,
      "should be able to access to the BUD constant to directory with bud overriding methods"
    assert_not_nil WLBud::BUD_GEM_VERSION,
      "should be able to access to the BUD version used"
    assert_not_nil WLBud::VERSION,
      "should be able to access to the WLBud gem version used"
    
  end
end
