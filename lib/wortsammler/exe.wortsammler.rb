
require "optparse"                       # for option parser
require 'wortsammler/log_helper'
require 'wortsammler/init_project.rb'
require 'wortsammler/class.proolib.rb'
require 'wortsammler/class.Traceable.rb'
require 'wortsammler/class.Traceable.md.rb'

require 'wortsammler/version.rb'


options = {}
config = nil

optparse = OptionParser.new do|opts|
  # Set a banner, displayed at the top
  # of the help screen.
  opts.banner = ["This is Wortsammler #{Wortsammler::VERSION}",
                 "",
                 "Usage: Wortsammler [options]"
                 ].join("\n")

  ##
  # Define the options, and what they do

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
  end

  options[:init] = false
  opts.on( '-i', '--init DIR', 'create a project folder in DIR' ) do|file|
    options[:init] = file
  end

  options[:beautify_path] = false
  opts.on( '-b', '--beautify_path PATH', 'bautify markdown on PATH  a project folder or a single document' ) do|file|
    options[:beautify_path] = file
  end

  options[:beautify_doc] = false
  opts.on( nil, '--beautify_doc', 'bautify markdownfiles of mentioned in document manifest' ) do
    options[:beautify_doc] = true
  end


  options[:input_path] = false
  opts.on( '-i', '--input PATH', 'format input file on PATH a (project folder or single document)') do|path|
    options[:input_path] = path
  end

  options[:outputformats] = ['pdf']
  opts.on( '-f', '--format formatList', 'set the outputformat to formatList' ) do|formatlist|
    options[:outputformats] = formatlist.split(":")
  end

  options[:outputfolder] = false
  opts.on( '-o', '--output PATH', 'set the output to PATH' ) do|path|
    options[:outputfolder] = path
  end

  options[:manifest] = false
  opts.on( '-m', '--manifest PATH', 'set mainfest input to PATH' ) do|file|
    options[:manifest] = file
  end

  options[:collect] = false
  opts.on( '-c', '--collect', 'collect traceables by manifest' ) do
    options[:collect] = true
  end

  options[:process] = false
  opts.on( '-p', '--process', 'process documents by manifest' ) do
    options[:process] = true
  end

end

##
# now parse the commandline
#
begin
  optparse.parse!
rescue OptionParser::ParseError => option
  $log.error "Invalid option #{option}"
  exit

rescue RegexpError => error
  $log.error "#{error}"
  exit
end


module Wortsammler
  def self.wortsammler_execute(options)
    ##
    #
    # print version info
    #
    if options[:version] then
      puts "Wortsammler #{Wortsammler::VERSION}"

      pandoc=`pandocx -v`.split("\n")[0] rescue pandoc="error running pandoc"
      xetex=`xelatex -v`.split("\n")[0] rescue pandoc="error running xelatex"

      puts "found #{pandoc}"
      puts "found #{xetex}"

    end

    ##
    # initialize a project
    #
    if project_folder=options[:init] then
      if File.exists?(project_folder)
        $log.error "directory already exists: '#{project_folder}'"
        exit(false)
      end
      Wortsammler::init_folders(project_folder)
    end


    ##
    #
    # load the manifest
    #
    if config_file=options[:manifest] then
      config =  ProoConfig.new(config_file)
    end

    ##
    #
    # beautify markdown files on path
    #
    #
    if clean_path = options[:beautify_path] then
      cleaner = PandocBeautifier.new($log)
      unless File.exists? clean_path then
        $log.error "cannot beautify non existing path '#{clean_path}'"
        exit(false)
      end
      if File.file?(clean_path)  #(RS_Mdc)
        cleaner.beautify(clean_path)
      elsif File.exists?(clean_path)
        files=Dir["#{clean_path}/**/*.md", "#{clean_path}/**/*.markdown"]
        files.each{|f| cleaner.beautify(f)}
      else
        nil
      end
    end

    ##
    #
    # beautify markdown files by manifest
    #
    #
    if options[:beautify_doc] then

      if config.nil? then
        $log.error "no manifest specified. Please use -m to specify a manifest"
        exit(0)
      else
        cleaner = PandocBeautifier.new($log)
        config.files.each{|f| cleaner.beautify(f)}
      end
    end


    ##
    # process documents in the manifest
    #
    if options[:collect] then
      if config.nil? then
        $log.error "no manifest specified to collect traces. Please use -m to specify a manifest"
        exit(0)
      else
        Wortsammler.collect_traces(config)
      end
    end

    ##
    # process documents in the manifest
    #
    if options[:process] then
      if config.nil? then
        $log.error "no manifest specified to prorcess document. Please use -m to specify a manifest"
        exit(0)
      else

        PandocBeautifier.new.generateDocument(config.input,
                                              config.outdir,
                                              config.outname,
                                              config.format,
                                              config.vars,
                                              config.editions,
                                              config.snippets,
                                              config)
      end
    end

    ##
    # take output formats
    #
    if options[:outputformats] then
      outputformats = options[:outputformats]
    end

    ##
    # take output folder
    #
    if options[:outputfolder] then
      outputfolder = options[:outputfolder]
    end

    ##
    #
    # beautify markdown files on path
    #
    #
    if input_path = options[:input_path] then
      if outputfolder.nil? then
        $log.error "no outputfolder specified"
        exit(0)
      end

      unless File.exists?(outputfolder) then
        $log.info "creating folder '#{outputfolder}'"
        FileUtils.mkdir_p(outputfolder)
      end

      cleaner = PandocBeautifier.new($log)
      unless File.exists? input_path then
        $log.error "cannot process non existing path '#{input_path}'"
        exit(false)
      end
      if File.file?(input_path)  #(RS_Mdc)
        cleaner.render_single_document(input_path, outputfolder, outputformats)
      elsif File.exists?(input_path)
        files=Dir["#{input_path}/**/*.md", "#{input_path}/**/*.markdown"]
        files.each{|f| cleaner.render_single_document(f, outputfolder, outputformats)}
      else
        nil
      end
    end
  end
end

Wortsammler.wortsammler_execute(options)
