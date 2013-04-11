require 'debugger'
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

  opts.separator ""

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

  opts.separator nil

  options[:init] = false
  opts.on( "-n", '--init DIR', 'create a project folder in DIR' ) do|file|
    options[:init] = file
  end


  opts.separator nil

  options[:input_path] = false
  opts.on( '-i', '--input PATH', 'set input file/project folder for processing') do|path|
    options[:input_path] = path
  end

  options[:manifest] = false
  opts.on( '-m', '--manifest PATH', 'set mainfest file for processing' ) do|file|
    options[:manifest] = file
  end

  opts.separator nil

  options[:outputformats] = ['pdf']
  opts.on( '-f', '--format formatList', 'set the outputformat to formatList' ) do|formatlist|
    options[:outputformats] = formatlist.split(":")
  end

  options[:outputfolder] = false
  opts.on( '-o', '--output PATH', 'set the output to PATH' ) do|path|
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
    config=nil
    if config_file=options[:manifest] then
      config =  ProoConfig.new(config_file)
    end

    ##
    # process input path
    #
    #
    input_files=nil
    if input_path = options[:input_path]
      unless File.exists? input_path then
        $log.error "path does not exist path '#{input_path}'"
        exit(false)
      end
      if File.file?(input_path)  #(RS_Mdc)
        input_files=[input_path]
      elsif File.exists?(input_path)
        input_files=Dir["#{input_path}/**/*.md", "#{input_path}/**/*.markdown"]
      end
    end

    ##
    #
    # beautify markdown files
    #
    #
    cleaner = PandocBeautifier.new($log)

    if options[:beautify]


      # process path

      if input_files then
        input_files.each{|f| cleaner.beautify(f)}
      end

      # process manifest

      if config then
        config.files.each{|f| cleaner.beautify(f)}
      end

      unless input_files or config
        $log.error "no input specified. Please use -m or -i to specify input"
        exit false
      end
    end

    ##
    # process collect in markdown files
    #

    if options[:collect]

      # collect by path

      if input_files then
        $log.warn "collect from path not yet implemented"
      end

      # collect by manifest

      if config then
        Wortsammler.collect_traces(config)
      end

      unless input_files or config
        $log.error "no input specified. Please use -m or -i to specify input"
        exit false
      end
    end



    ##
    #  process files
    #
    if options[:process]

      if input_files then

        if options[:outputformats] then
          outputformats = options[:outputformats]
        end

        if options[:outputfolder] then
          outputfolder = options[:outputfolder]
        else
          $log.error "no output folder specified"
          exit false
        end

        unless File.exists?(outputfolder) then
          $log.info "creating folder '#{outputfolder}'"
          FileUtils.mkdir_p(outputfolder)
        end

        input_files.each{|f| cleaner.render_single_document(f, outputfolder, outputformats)}
      end

      # collect by manifest

      if config then
        cleaner.generateDocument(config.input,
                                 config.outdir,
                                 config.outname,
                                 config.format,
                                 config.vars,
                                 config.editions,
                                 config.snippets,
                                 config)
      end

      unless input_files or config
        $log.error "no input specified. Please use -m or -i to specify input"
        exit false
      end
    end

  end #execute


  def self.verify_options(options)
    if options[:input_path] or options[:manifest] then
      unless options[:process] or options[:beautify] or options[:collect] then
        $log.error "no procesing option (p, b, c) specified"
        exit false
      end
    end

    if options[:input_path] and options[:process] then
      unless options[:outputfolder] then
        $log.error "no output folder specified for input path"
        exit false
      end
    end
  end #verify_options

end # module

Wortsammler.verify_options(options)
Wortsammler.wortsammler_execute(options)
