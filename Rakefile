require "bundler/gem_tasks"
require 'rake/clean'
require 'rspec/core/rake_task'
#require 'ruby-debug'
 
CLEAN << "testproject"

desc "Run specs"
RSpec::Core::RakeTask.new do |t|
  t.pattern = "./spec/**/*_spec.rb" # don't need this, it's default.
  t.rspec_opts = ['-d -fd -fd --out ./testresults/wortsammler_testresults.log -fh --out ./testresults/wortsammler_testresults.html']
  # Put spec opts in a file named .rspec in root
end
 
desc "Generate code coverage"
RSpec::Core::RakeTask.new(:coverage) do |t|
  t.pattern = "./spec/**/*_spec.rb" # don't need this, it's default.
  t.rcov = true
  t.rcov_opts = ['--exclude', 'spec']
end

desc "create documentation"
task :doc do
	sh "yard doc"
end

task :build => :doc do
	sh "wortsammler -bi README.md"
	sh "wortsammler -pi README.md -o ."
end

desc "run tests"
task :test => [:clean, :spec]

task :default do
	rake -T
end	
