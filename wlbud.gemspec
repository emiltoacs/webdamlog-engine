# -*- mode: ruby; encoding: utf-8 -*-

# maybe usefull since I also have it in rails

$:.push File.expand_path("lib", __FILE__)
require "wlbud/version"

Gem::Specification.new do |s|
  s.name        = "wlbud"
  s.version     = NAME::VERSION
  s.authors     = ["Émilien Antoine", "Jules Testard"]
  s.email       = []
  s.homepage    = ""
  s.summary     = %q{TODO: Write a gem summary}
  s.description = %q{TODO: Write a gem descripteion}

  s.rubyforge_project = "none"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
end
