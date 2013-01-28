# -*- coding: utf-8 -*-
#  File name ts_webdamlog.rb
#  Copyright © by INRIA
#
#  Contributors : Webdam Team <webdam.inria.fr>
#       Emilien Antoine <emilien[dot]antoine[@]inria[dot]fr>
#
#   WebdamLog - Jun 28, 2012
#
#   Encoding - UTF-8
# Add the test directory to the basic load path
$:.unshift File.dirname(__FILE__)
require 'header_test'

# This file is the test suite file used to lauch all the test defined for this
# project. It has a very simple goal: load all files in this directory with a
# name starting with the prefix tc_ therefore the test files should be named
# with this prefix.

# This flag $quick-mode could be use to skip the most expensive time test file
if  ARGV.include?("quick")
  $quick_mode = true
end

if  ARGV.include?("verbose")
  $test_verbose = true
end


files = Dir.entries(File.dirname(__FILE__)).select do |file|
  file =~ /tc_.*\.rb$/
end

# I prefer to specify my own order instead of the default alphabetical order.
#
# The problem is to think to add the new test files in the list when created.
#
if  ARGV.include?("ordered")
  require "tc_bud_collection.rb"
  require "tc_bud_delete_fact.rb"
  require "tc_meta_test.rb"
  require "tc_wl_wlbud_tools.rb"
  require "tc_wl_wlbud_misc.rb"
  require "tc_wl_wlbud_parse_program.rb"
  require "tc_wl_program_treetop.rb"
  require "tc_wl_wlbud_local_1_evaluation.rb"
  require "tc_wl_wlbud_local_2_add_source_relation.rb"
  require "tc_wl_wlbud_callback.rb"
  require "tc_wl_wlbudl_send_packet.rb"
  require "tc_wl_wlbud_delegation_1_simple.rb"
  require "tc_wl_wlbud_delegation_2_complex.rb"
  require "tc_wlbud_async_update.rb"
else
  files.each { |file| require file }  
end

