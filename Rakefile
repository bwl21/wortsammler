require "bundler/gem_tasks"
require 'rake/clean'
require 'rspec/core/rake_task'
#require 'ruby-debug'

CLEAN << "testproject"

desc "Run specs"
RSpec::Core::RakeTask.new(:spec, :focus) do |t, args|
  t.pattern = "./spec/**/*_spec.rb" # don't need this, it's default.
  if args[:focus] then
    usetags="-e #{args[:focus]}"
  else
    usetags=nil #"--tag ~exp"
  end
  t.rspec_opts = [usetags,
                  " -fd -fd --out ./testresults/wortsammler_testresults.log -fh --out ./testresults/wortsammler_testresults.html"]
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
  sh "bin/wortsammler -bi README.md"
  sh "bin/wortsammler -bi changelog.md"
  sh "yard --markup markdown doc ."
end

desc "get the default stylefiles from pandoc" 
task :getpandocstyles do
  [:latex, :docx, :html, :epub].each{|format |sh "pandoc -D #{format} > resources/pandocdefault.#{format}"}
  end

desc "run tests"
task :test  => [:clean, :spec]

task :default do
  sh "rake -T"
end
