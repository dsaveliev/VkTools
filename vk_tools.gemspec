# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "vk_tools/version"

Gem::Specification.new do |s|
  s.name        = "vk_tools"
  s.version     = VkTools::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Dmitry Saveliev"]
  s.email       = ["d.e.saveliev@gmail.com"]
  s.homepage    = ""
  s.summary     = %q{Classes for access vkontakte.ru content and rest services}
  s.description = %q{Classes for access vkontakte.ru content and rest services}

  s.rubyforge_project = "vk_tools"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_runtime_dependency("nokogiri")
  s.add_runtime_dependency("awesome_print")
  s.add_runtime_dependency("oauth2", ">= 0.5.2")
  s.add_runtime_dependency("mechanize")
  s.add_runtime_dependency("json")
  s.add_runtime_dependency("redis", "~> 2.2.1")
  #s.add_runtime_dependency("SystemTimer")

  s.add_development_dependency("rspec-rails")
  s.add_development_dependency("yard")
  s.add_development_dependency("rake")
  s.add_development_dependency("fakeweb")
  s.add_development_dependency("webmock")
  s.add_development_dependency("vcr", "2.0.0.rc1")
  s.add_development_dependency("pry")
end
