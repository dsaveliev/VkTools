# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "vk_tools/version"

Gem::Specification.new do |s|
  s.name        = "vk_tools"
  s.version     = VkTools::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["TODO: Write your name"]
  s.email       = ["TODO: Write your email address"]
  s.homepage    = ""
  s.summary     = %q{TODO: Write a gem summary}
  s.description = %q{TODO: Write a gem description}

  s.rubyforge_project = "vk_tools"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_runtime_dependency("nokogiri")
  s.add_runtime_dependency("awesome_print")
  s.add_runtime_dependency("mechanize")
  s.add_runtime_dependency("json")

  s.add_development_dependency("rspec", ["~> 2.5"])
  s.add_development_dependency("rspec-rails", ["~> 2.5"])
  s.add_development_dependency("capybara")
  s.add_development_dependency("rcov")
  s.add_development_dependency("yard")
end
