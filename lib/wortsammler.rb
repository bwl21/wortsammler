require "wortsammler/version"
require "wortsammler/class.proolib"


##
# This represents the high level API of Wortsammler

module Wortsammler


  #
  # execute Wortsammler after parsing the command line
  #
  # @param  options [Hash] The parsed commandline arguments.
  #
  #         The key of each entry is the argument name as a symbol
  #
  #         The value of each entry is the value of the argument
  #
  #         No default handling is performed, since defaulting of arguments has been done
  #         on the commandline processor.
  #
  # @return [Nil] No Return
  def self.execute(options)


    PandocBeautifier.new($log).check_pandoc_version

    ##
    #
    # print version info
    #
    if options[:version] then
      puts "this is #{Wortsammler::PROGNAME} version #{Wortsammler::VERSION}\n"

      pandoc=`#{PANDOC_EXE} -v`.split("\n")[0] rescue pandoc="error running pandoc"
      xetex=`#{LATEX_EXE} -v`.split("\n")[0] rescue pandoc="error running xelatex"

      $log.info "found #{pandoc}"
      $log.info "found #{xetex}"

      $log.debug("debug mode turned on")

      l= "-----------------"
      $log.info l
      options.each { |k, v| $log.info "#{k}: #{v}" }
      $log.info l
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
    # load the manifest or use default configuration
    #
    config = ProoConfig.new();
    if config_file=options[:manifest] then
      config.load_from_file(config_file)
    end

    ##
    # process input path
    #
    #
    input_files=nil
    if inputpath = options[:inputpath]
      unless File.exists? inputpath then
        $log.error "path does not exist path '#{inputpath}'"
        exit(false)
      end
      if File.file?(inputpath) #(RS_Mdc)
        input_files=[inputpath]
      elsif File.exists?(inputpath)
        input_files=Dir["#{inputpath}/**/*.md", "#{inputpath}/**/*.markdown", "#{inputpath}/**/*.plantuml"]
      end
    end

    ##
    #
    # beautify markdown files
    #
    #

    if options[:beautify]

      # process path
      if input_files then
        Wortsammler.beautify(input_files, config)
      end

      # process manifest
      if config.input then
        Wortsammler.beautify(config.input, config)
      end

      unless input_files or config
        $log.error "no input specified. Please use -m or -i to specify input"
        exit false
      end
    end

    #
    # plantuml markdown files
    #
    #

    if options[:plantuml]

      # process path
      if input_files then
        Wortsammler.plantuml(input_files)
      end

      # process manifest

      if config.input then
        Wortsammler.plantuml(config.input)
      end

      unless input_files or config.input
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

      if config.input then
        Wortsammler.collect_traces(config)
      end

      unless input_files or config.input
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
          outputformats = options[:outputformats].split(":")
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

        input_files.each { |f| Wortsammler.render_single_document(f, outputfolder, outputformats, config) }
      end

      # collect by manifest

      if config.input then
        Wortsammler.process(config)
      end

      unless input_files or config
        $log.error "no input specified. Please use -m or -i to specify input"
        exit false
      end
    end

    nil
  end

  #execute


  #
  # beautify a list of Documents
  # @param  paths [Array of String] Array of filenames which shall be cleaned.
  # @param [ProoConfig] config
  #
  # @return [Nil] no return
  def self.beautify(paths, config=nil)

    cleaner = PandocBeautifier.new($log)
    cleaner.config = config if config

    paths.each { |f| cleaner.beautify(f) }
    nil
  end


  #
  # plantuml a list of Documents
  # @param  paths [Array of String] Array of filenames which shall be converted.
  # @param [ProoConfig] config
  #
  # @return [Nil] no return
  def self.plantuml(paths)

    plantumljar=File.dirname(__FILE__)+"/../resources/plantuml.jar"

    paths.each { |f|
      cmd          = "java -jar \"#{plantumljar}\" -v \"#{f}\" 2>&1"
      r            =`#{cmd}`
      no_of_images = r.split($/).grep(/Number of image/).first.split(":")[1]

      $log.info("#{no_of_images} uml diagram(s) in #{File.basename(f)}")
      $log.info(r) unless $?.success?
    }
    nil
  end


  #
  # process the documents according to the manifest
  #
  # @param  config [ProoConfig] A configuration object representing the manifest.
  #
  # @return [Nil] no return
  def self.process(config)
    cleaner = PandocBeautifier.new($log)
    cleaner.config = config

    cleaner.generateDocument(config.input,
                             config.outdir,
                             config.outname,
                             config.format,
                             config.vars,
                             config.editions,
                             config.snippets,
                             config.frontmatter,
                             config)

    nil

  end


  #
  # render a single document
  # @param  filename [String] The filename of the document file which shall be rendered
  # @param  outputfolder [String] The path to the outputfolder where the output files shall be placed.
  # @param [ProoConfig] config
  #
  #
  # @param  outputformats [Array of String] The list of formats which shall be produced
  #
  # @return [Nil] no return
  def self.render_single_document(filename, outputfolder, outputformats, config=nil)
    cleaner = PandocBeautifier.new($log)
    cleaner.config = config if config
    cleaner.render_single_document(filename, outputfolder, outputformats)
    nil
  end

  #
  # initialize a project directory. It creates a bunch of
  # folders, a root document, a manifest and an intial rakefile
  #
  # @param  root [String] [The path to the root folder of the sample project]
  #
  # @return [Nil] No return
  def self.init_folders(root)

    folders=["ZSUPP_Manifests",
             "ZGEN_Documents",
             "ZSUPP_Tools",
             "ZSUPP_Styles",
             "ZGEN_RequirementsTracing",
             "001_Main",
             "900_snippets"
    ]

    folders.each { |folder|
      FileUtils.mkdir_p("#{root}/#{folder}")
    }

    resourcedir=File.dirname(__FILE__)+"/../resources"
    Dir["#{resourcedir}/*.yaml"].each { |f|
      FileUtils.cp(f, "#{root}/ZSUPP_Manifests")
    }
    FileUtils.cp("#{resourcedir}/main.md", "#{root}/001_Main")
    FileUtils.cp("#{resourcedir}/rakefile.rb", "#{root}/ZSUPP_Tools")
    FileUtils.cp("#{resourcedir}/default.wortsammler.latex", "#{root}/ZSUPP_Styles")
    FileUtils.cp("#{resourcedir}/logo.jpg", "#{root}/ZSUPP_Styles")
    FileUtils.cp("#{resourcedir}/snippets.xlsx", "#{root}/900_snippets")

    nil
  end


  #
  # collect the Traceables in a document specified by a manifest
  # @param  config [ProolibConfig] the manifest model
  #
  # @return [Nil] no  return
  def self.collect_traces(config)

    files   = config.input # get the input files
    rootdir = config.rootdir # get the root directory

    downstream_tracefile = config.downstream_tracefile # String to save downstram filenames
    reqtracefile_base    = config.reqtracefile_base # string to determine the requirements tracing results
    upstream_tracefiles  = config.upstream_tracefiles # String to read upstream tracefiles

    traceable_set = TraceableSet.new

    # collect all traceables in input
    files.each { |f|
      x=TraceableSet.processTracesInMdFile(f)
      traceable_set.merge(x)
    }

    # collect all upstream traceables
    #
    upstream_traceable_set=TraceableSet.new
    unless upstream_tracefiles.nil?
      upstream_tracefiles.each { |f|
        x=TraceableSet.processTracesInMdFile(f)
        upstream_traceable_set.merge(x)
      }
    end

    # check undefined traces
    all_traceable_set=TraceableSet.new
    all_traceable_set.merge(traceable_set)
    all_traceable_set.merge(upstream_traceable_set)
    undefineds=all_traceable_set.undefined_ids
    $log.warn "undefined traces: #{undefineds.join(' ')}" unless undefineds.empty?


    # check duplicates
    duplicates=all_traceable_set.duplicate_traces
    if duplicates.count > 0
      $log.warn "duplicated trace ids found:"
      duplicates.each { |d| d.each { |t| $log.warn "#{t.id} in #{t.info}" } }
    end

    # write traceables to the intermediate Tracing file
    outname                     ="#{rootdir}/#{reqtracefile_base}.md"

    # poke ths sort order for the traceables
    all_traceable_set.sort_order=config.traceSortOrder if config.traceSortOrder
    traceable_set.sort_order    =config.traceSortOrder if config.traceSortOrder
    # generate synopsis of traceableruby 1.8.7 garbage at end of file


    tracelist                   =""
    File.open(outname, "w") { |fx|
      fx.puts ""
      fx.puts "\\clearpage"
      fx.puts ""
      fx.puts "# Requirements Tracing"
      fx.puts ""
      tracelist=all_traceable_set.reqtraceSynopsis(:SPECIFICATION_ITEM)
      fx.puts tracelist
    }

    # output the graphxml
    # write traceables to the intermediate Tracing file
    outname="#{rootdir}/#{reqtracefile_base}.graphml"
    File.open(outname, "w") { |fx| fx.puts all_traceable_set.to_graphml }

    outname="#{rootdir}/#{reqtracefile_base}Compare.txt"
    File.open(outname, "w") { |fx| fx.puts traceable_set.to_compareEntries }

    # write the downstream_trace file - to be included in downstream - speciifcations
    outname="#{rootdir}/#{downstream_tracefile}"
    File.open(outname, "w") { |fx|
      fx.puts ""
      fx.puts "\\clearpage"
      fx.puts ""
      fx.puts "# Upstream Requirements"
      fx.puts ""
      fx.puts traceable_set.to_downstream_tracefile(:SPECIFICATION_ITEM)
    } unless downstream_tracefile.nil?


    # now add the upstream traces to input
    files.concat(upstream_tracefiles) unless upstream_tracefiles.nil?

    nil
  end

  private
  #
  # This method can verify wortsammler options delivered by option parser
  # @param  options [Hash] Option hash delivered by option parser
  #
  # @return [Boolean] true if successful. otherwise exits the program
  def self.verify_options(options)

    if options[:process] or options[:beautify] or options[:coollect] then
      unless options[:inputpath] or options[:manifest] then
        $log.error "no input specified"
        exit false
      end
    end

    if options[:inputpath] or options[:manifest] then
      unless options[:process] or options[:beautify] or options[:collect] or options[:plantuml] then
        $log.error "no procesing option (p, b, c, u) specified"
        exit false
      end
    end

    unless options[:outputfolder] then
      outputfolder="."
      inputpath   =options[:inputpath]
      unless inputpath.nil? then
        outputfolder = inputpath if File.directory?(inputpath)
        outputfolder = File.dirname(inputpath) if File.file?(inputpath)
      end
      options[:outputfolder] = outputfolder
    end

    if options[:inputpath] and options[:process] then
      unless options[:outputfolder] then
        $log.error "no output folder specified for input path"
        exit false
      end
    end

    true
  end #verify_options


end # module