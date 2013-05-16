#!/usr/bin/env ruby
# This code is the same as the executable budvis but it include the bud methods
# override in wlbud
require 'rubygems'
require 'dbm'
require 'bud'
require 'bud/graphs'
require 'bud/viz_util'
# snippet used to allow to load wlbud by other means that using gems
begin
  require_relative '../lib/wlbud'
rescue LoadError
  require 'rubygems'
  require 'wlbud'
end

include VizUtil

# Add default file is the last DBM* directory created
unless ARGV[0]
  BUD_DBM_DIR = Dir.glob("DBM*").sort_by{|f| File.mtime(f)}.last
  puts "Default file choosen #{BUD_DBM_DIR}"
else
  BUD_DBM_DIR = "#{ARGV[0]}"
end


def usage
  puts "Usage:"
  puts "Running a Bud program with option :trace => true will cause a DBM directory DBM_dir to be created (Class_ObjectId_Port)"
  puts "> budvis DBM_dir"
  puts "This will create a series of svg files in DBM_dir, the root of which will be named tm_0.svg.  Open in a browser.\n"
  puts "e.g."
  puts "> ruby test/tc_carts.rb"
  puts "> budvis DBM_BCS_2159661360_"
  puts "> open DBM_BCS_2159661360_/tm_0.svg"
  puts "\nWith the SVG file open in a browser, you may navigate forward and backward in time"
  puts "by clicking the T and S nodes, respectively."
  exit
end

usage unless BUD_DBM_DIR
usage if ARGV[0] == '--help'

meta, data = get_meta2(BUD_DBM_DIR)

# prune outbufs from tabinf
tabinf = meta[:tabinf].find_all do |k|
  !(k[1] == "Bud::BudChannel" and k[0] =~ /_snd\z/)
end

vh = VizHelper.new(tabinf, meta[:cycle], meta[:depends], meta[:rules], BUD_DBM_DIR, meta[:provides], meta[:depends_time])
data.each do |d|
  vh.full_info << d
end
vh.tick
vh.summarize(BUD_DBM_DIR, meta[:schminf])
