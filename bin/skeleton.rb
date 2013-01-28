#!/usr/bin/env ruby

# snippet used to allow to load wlbud by other means that using gems
begin
  require 'wlbud'
rescue LoadError
  require 'rubygems'
  require 'wlbud'
end

#more code goes here
