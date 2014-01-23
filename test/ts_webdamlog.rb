# #!/usr/bin/env ruby
#
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

# This file is the test suite file used to launch all the test defined for this
# project. It has a very simple goal: load all files in this directory with a
# name starting with the prefix tc_ therefore the test files should be named
# with this prefix.

# Simple debug constant to trigger debug messages in tests
DEBUG = false unless defined?(DEBUG)

# This flag $quick-mode could be use to skip the most expensive time test file
if  ARGV.include?("quick")
  ARGV.delete("quick")
  $quick_mode = true
end

if  ARGV.include?("verbose")
  ARGV.delete("verbose")
  $test_verbose = true
end

files = []
Dir.chdir(File.dirname(__FILE__)) do
  Dir.glob('**/tc_*.rb').each do|f|
    files << f
  end
end

# Invoke with ./ts_webdamlog.rb ordered
if ARGV.include?("ordered")
  ARGV.delete("ordered")
  p "test suite in order"
  require "30_provenance/tc_wl_trace_push_out.rb"
  require "10_first_gen/tc_wl_wlbud_dynamic.rb"
  require "10_first_gen/tc_wl_runner.rb"
  require "10_first_gen/tc_wl_measure.rb"
  require "10_first_gen/tc_wl_wlbud_async_update.rb"
  require "10_first_gen/tc_non_local.rb"
  require "10_first_gen/tc_wl_wlbud_parse_program.rb"
  require "10_first_gen/tc_wl_program_treetop.rb"
  require "10_first_gen/tc_wl_wlbud_delay_load_fact.rb"
  require "20_deleg_seeds/tc_wl_program.rb"
  require "20_deleg_seeds/tc_wl_seed.rb"
  require "20_deleg_seeds/tc_wl_four_peers_program.rb"
  require "20_deleg_seeds/tc_wl_pending_delegations.rb"
  require "20_deleg_seeds/tc_peer_vars.rb"
  require "20_deleg_seeds/tc_wl_selfjoin_rewriting.rb" 
else
  files.each { |file| require file }
  
  # puts files.map { |file| "require \"#{File.basename file}\"" }

  # puts files.map { |file| "require \"#{file}\"" }
end

# clean rule dir created during tests
require 'fileutils'
FileUtils.rm_rf(WLBud::WL.get_path_to_rule_dir, :secure => true)
