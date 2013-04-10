##
#
# (c) 2013 Bernhard Weichel
#
#

require 'fileutils'


module Wortsammler


  #
  # Initialize a project directory. It creates a bunch of
  # folders, a root document, a manifest and an intial rakefile
  #
  # @param  root [String] [The path to the root folder of the sample project]
  #
  # @return [Boolean] [always true]
  def self.init_folders(root)

    folders=["ZSUPP_Manifests",
             "ZGEN_Documents",
             "ZSUPP_Tools",
             "ZSUPP_Styles",
             "ZGEN_RequirementsTracing",
             "001_Main"
             ]

    folders.each{|folder|
      FileUtils.mkdir_p("#{root}/#{folder}")
    }

    resourcedir=File.dirname(__FILE__)+"/../../resources"
    Dir["#{resourcedir}/*.yaml"].each{|f|
      FileUtils.cp(f, "#{root}/ZSUPP_Manifests")
    }
    FileUtils.cp("#{resourcedir}/main.md", "#{root}/001_Main")
    FileUtils.cp("#{resourcedir}/rakefile.rb", "#{root}/ZSUPP_Tools")
    FileUtils.cp("#{resourcedir}/default.latex", "#{root}/ZSUPP_Styles")
    FileUtils.cp("#{resourcedir}/logo.jpg", "#{root}/ZSUPP_Styles")

    true
  end

  def self.collect_traces(config)

    files = config.input                               # get the input files
    rootdir = config.rootdir                           # get the root directory 

    downstream_tracefile = config.downstream_tracefile # String to save downstram filenames
    reqtracefile_base = config.reqtracefile_base       # string to determine the requirements tracing results
    upstream_tracefiles = config.upstream_tracefiles   # String to read upstream tracefiles

    traceable_set = TraceableSet.new

    # collect all traceables in input
    files.each{|f|
      x=TraceableSet.processTracesInMdFile(f)
      traceable_set.merge(x)
    }

    # collect all upstream traceables
    #
    upstream_traceable_set=TraceableSet.new
    unless upstream_tracefiles.nil?
      upstream_tracefiles.each{|f|
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
      $logger.warn "duplicated trace ids found:"
      duplicates.each{|d| d.each{|t| $log.warn "#{t.id} in #{t.info}"}}
    end

    # write traceables to the intermediate Tracing file
    outname="#{rootdir}/#{reqtracefile_base}.md"

    # poke ths sort order for the traceables
    all_traceable_set.sort_order=config.traceSortOrder if config.traceSortOrder
    traceable_set.sort_order=config.traceSortOrder if config.traceSortOrder
    # generate synopsis of traceableruby 1.8.7 garbage at end of file


    tracelist=""
    File.open(outname, "w"){|fx|
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
    File.open(outname, "w") {|fx| fx.puts all_traceable_set.to_graphml}

    outname="#{rootdir}/#{reqtracefile_base}Compare.txt"
    File.open(outname, "w") {|fx| fx.puts traceable_set.to_compareEntries}

    # write the downstream_trace file - to be included in downstream - speciifcations
    outname="#{rootdir}/#{downstream_tracefile}"
    File.open(outname, "w") {|fx|
      fx.puts ""
      fx.puts "\\clearpage"
      fx.puts ""
      fx.puts "# Upstream Requirements"
      fx.puts ""
      fx.puts traceable_set.to_downstream_tracefile(:SPECIFICATION_ITEM)
    } unless downstream_tracefile.nil?


    # now add the upstream traces to input
    files.concat( upstream_tracefiles) unless upstream_tracefiles.nil?

  end


end
