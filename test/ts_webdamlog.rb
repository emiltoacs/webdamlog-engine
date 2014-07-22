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
  Dir.glob('**/tc_*.rb').sort.each do|f|
    files << f
  end
end

# Invoke with ./ts_webdamlog.rb ordered
if ARGV.include?("ordered")
  ARGV.delete("ordered")
  p "test suite in order"
  #  add here the list of require to execute in order  
else
  files.each { |file| require file }
  # puts files.map { |file| "require \"#{File.basename file}\"" }
  #  puts files.map { |file| "require \"#{file}\"" }
end

# clean rule dir created during tests
require 'fileutils'
FileUtils.rm_rf(WLBud::WL.get_path_to_rule_dir, :secure => true)
