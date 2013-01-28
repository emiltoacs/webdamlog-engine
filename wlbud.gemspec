# -*- mode: ruby; encoding: utf-8 -*-
# 
# seems to be the good way to create gems
#

# $:.push File.expand_path("lib", __FILE__)
require "lib/wlbud/version"

Gem::Specification.new do |s|
  s.name        = "wlbud"
  s.version     = WLBud::VERSION
  s.extra_rdoc_files = ['README', 'LICENSE']
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Émilien Antoine", "Jules Testard"]
  s.email       = ["first.last@inria.fr"]
  s.homepage    = "http://webdam.inria.fr/"
  s.summary     = %q{Write a gem summary}
  s.description = %q{Write a gem description}
  s.required_ruby_version = '>= 1.8.7'
  s.rubyforge_project = "none"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
#  s.default_executable = 'rebl'
  s.require_paths = ["lib"]
  s.bindir = "bin"

  s.add_dependency 'bud', ">= #{WLBud::BUD_GEM_VERSION}"
end
