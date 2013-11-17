require "optparse"                       # for option parser
require 'wortsammler'
require 'wortsammler/log_helper'
require 'wortsammler/class.proolib.rb'
require 'wortsammler/class.Traceable.rb'
require 'wortsammler/class.Traceable.md.rb'
require 'wortsammler/version.rb'


options = {}
config = nil
$log.progname="#{Wortsammler::PROGNAME} #{Wortsammler::VERSION}"

optparse = OptionParser.new do|opts|
  # Set a banner, displayed at the top
  # of the help screen.
  opts.banner = ["This is Wortsammler #{Wortsammler::VERSION}",
                 "",
                 "Usage: Wortsammler [options]",
                 "",
                 "examples:",
                 "",
                 "   wortsammler -cbpm mymanifest.yaml",
                 "       -- beautify collect process files from mymanifest.yaml",
                 "",
                 "   wortsammler -cbpi .",
                 "       -- beautify collect process files in current folder"
                 ].join("\n")

  ##
  # Define the options, and what they do

  opts.separator nil
  opts.separator "options:"
  opts.separator nil

  # This displays the help screen, all programs are
  # assumed to have this option.
  opts.on( '-h', '--help', 'display this screen' ) do
    puts opts
    exit
  end


  options[:version] = false
  opts.on( "-v", '--version', 'print Version info, then turn on verbose mode' ) do
    options[:version] = true
    options[:verbose] = true
    $log.level=Logger::DEBUG
  end

  opts.separator nil

  options[:init] = nil
  opts.on( "-n", '--init DIR', 'create a project folder in DIR' ) do|file|
    options[:init] = file
  end


  opts.separator nil

  options[:inputpath] = nil
  opts.on( '-i', '--inputpath PATH', 'set input file/project folder for processing') do|path|
    options[:inputpath] = path
  end

  options[:manifest] = nil
  opts.on( '-m', '--manifest PATH', 'set mainfest file for processing' ) do|file|
    options[:manifest] = file
  end

  opts.separator nil

  options[:outputformats] = 'pdf'
  opts.on( '-f', '--outputformats formatList', 'set the outputformat to formatList' ) do|formatlist|
    options[:outputformats] = formatlist
  end

  options[:outputfolder] = nil
  opts.on( '-o', '--outputfolder PATH', 'set the output to PATH' ) do|path|
    options[:outputfolder] = path
  end


  opts.separator nil

  options[:collect] = false
  opts.on( '-c', '--collect', 'collect traceables by manifest' ) do
    options[:collect] = true
  end

  options[:process] = false
  opts.on( '-p', '--process', 'process documents by manifest' ) do
    options[:process] = true
  end


  options[:plantuml] = false
  opts.on( '-u', '--plantuml', 'plantuml documents by manifest' ) do
    options[:plantuml] = true
  end

  options[:beautify] = false
  opts.on( "-b", '--beautify', 'bautify markdownfiles' ) do
    options[:beautify] = true
  end

end

##
# now parse the commandline
#
begin
  optparse.parse!
rescue OptionParser::ParseError => option
  $log.error "Invalid option #{option}"
  exit false

rescue RegexpError => error
  $log.error "#{error}"
  exit
end

Wortsammler.verify_options(options)
Wortsammler.execute(options)
