# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'wortsammler/version'

Gem::Specification.new do |spec|
  spec.name          = "wortsammler"
  spec.version       = Wortsammler::VERSION
  spec.authors       = ["Bernhard Weichel"]
  spec.email         = ["github.com@nospam.weichel21.de"]
  spec.description   = <<END_DOC
  wortsammler is an environment to manage documentation.
  Basically it comprises of

  * a directory structure for source document sources
  * a manifest file to control the publication process
  * a tool to produce the doucments

  Particular features of wortsammler are
  * various output formats
  * support of requirement management
  * generate documents for different audiences based on 
    single sources
END_DOC

  spec.required_ruby_version = '>= 1.9.3'
  spec.add_runtime_dependency 'logger'
  spec.add_runtime_dependency 'nokogiri'
  spec.add_runtime_dependency "rubyXL"
  spec.add_runtime_dependency 'diffy', "~> 2.1.3"
  spec.add_runtime_dependency 'zip'
  spec.add_runtime_dependency 'treetop'

  spec.summary       = %q{an environment to manage documentation}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency 'debugger'
  spec.add_development_dependency 'yard'
  spec.add_development_dependency 'redcarpet'

end
