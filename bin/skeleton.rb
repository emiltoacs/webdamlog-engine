#!/usr/bin/env ruby

begin
  require 'mygem'
rescue LoadError
  require 'rubygems'
  require 'mygem'
end

#more code goes here
