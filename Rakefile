# -*- coding: utf-8 -*-
# -*- mode: ruby; mode: ruby-indent-tabs; mode: ruby-electric; -*-
require 'rubygems'
require 'rake'
require 'rake/clean'
require 'rake/gempackagetask'
require 'rake/rdoctask'
require 'rake/testtask'

$:.push File.expand_path("lib", __FILE__)
require "wlbud/version"

# Possibly merge the following with the next version
# spec = Gem::Specification.new do |s|
#   s.name = 'RubyApplication1'
#   s.version = '0.0.1'
#   s.has_rdoc = true
#   s.extra_rdoc_files = ['README', 'LICENSE']
#   s.summary = 'Your summary here'
#   s.description = s.summary
#   s.author = ''
#   s.email = ''
#   # s.executables = ['your_executable_here']
#   s.files = %w(LICENSE README Rakefile) + Dir.glob("{bin,lib,spec}/**/*")
#   s.require_path = "lib"
#   s.bindir = "bin"
# end

spec = Gem::Specification.new do |s|
  s.name        = "wlbud"
  s.version     = WLBud::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Émilien Antoine", "Jules Testard"]
  s.email       = []
  s.homepage    = ""
  s.summary     = %q{TODO: Write a gem summary}
  s.description = %q{TODO: Write a gem description}

  s.rubyforge_project = "none"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
end

Rake::GemPackageTask.new(spec) do |p|
  p.gem_spec = spec
  p.need_tar = true
  p.need_zip = true
end

Rake::RDocTask.new do |rdoc|
  files =['README', 'LICENSE', 'lib/**/*.rb']
  rdoc.rdoc_files.add(files)
  rdoc.main = "README" # page to start on
  rdoc.title = "RubyApplication1 Docs"
  rdoc.rdoc_dir = 'doc/rdoc' # rdoc output folder
  rdoc.options << '--line-numbers'
end

Rake::TestTask.new do |t|
  t.test_files = FileList['test/**/*.rb']
end
