# ####License####
#  File name project_conf.rb
#  Copyright © by INRIA
# 
#  Contributors : Webdam Team <webdam.inria.fr>
#       Emilien Antoine <emilien[dot]antoine[@]inria[dot]fr>
# 
#   WebdamLog - Aug 11, 2012
# 
#   Encoding - UTF-8
# ####License####
module Header
  $:.unshift File.dirname(__FILE__)
  require 'header_test'
end

# Test file to check configuration of the project
#
class ProjectConf < Test::Unit::TestCase
  include Header

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

    assert_not_nil WLBud::PROJECT_PATH, "need a path to the root of the project code"
    assert_not_nil WLBud::WLBUD_DIR_PATH, "need a path to the main directory of WLBud"
  end

end
