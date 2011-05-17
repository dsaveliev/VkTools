require 'bundler'
Bundler::GemHelper.install_tasks

require 'bundler/setup'

require 'rake'
require 'rspec/core'
require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:spec)
task :default => :spec

RSpec::Core::RakeTask.new(:rcov) do |t|
  t.rcov = true
  t.rcov_opts = %w[--rails]
  t.rcov_opts << "--exclude /gems/,/Library/,/usr/,spec,lib/tasks"
end
