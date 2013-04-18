#
# This script converts the trace-References in a markdown file
# to hot references.
#
# usage prepareTracingInPandoc <infile> <format> <outfile>
#
# Traces are formatted according to [RS_DM_008].
#
# Trace itself becomes the target, uptraces are converted to references.
#
# Traces can also be referenced by
#
#
require 'rubygems'
require 'yaml'
require 'tmpdir'
require 'nokogiri'
require "rubyXL"



# TODO: make these patterns part of the configuration

ANY_ANCHOR_PATTERN    = /<a\s+id=\"([^\"]+)\"\/>/
ANY_REF_PATTERN       = /<a\s+href=\"#([^\"]+)\"\>([^<]*)<\/a>/

TRACE_ANCHOR_PATTERN  = /\[(\w+_\w+_\w+)\](\s*\*\*)/
UPTRACE_REF_PATTERN   = /\}\( ((\w+_\w+_\w+) (,\s*\w+_\w+_\w+)*)\)/x
TRACE_REF_PATTERN     = /->\[(\w+_\w+_\w+)\]/

#                                      filename
#                                               heading
#                                                          level
#                                                                    pages to include
#                                                                                    pageclearance
INCLUDE_PDF_PATTERN   = /^\s+~~PDF\s+"(.+)" \s+ "(.+)" \s* (\d*) \s* (\d+-\d+)? \s* (clearpage|cleardoublepage)?~~/x

INCLUDE_MD_PATTERN    = /^\s+~~MD\s+"(.+)" \s+ "(.+)" \s* (\d*) \s* (\d+-\d+)? \s* (clearpage|cleardoublepage)?~~/x

SNIPPET_PATTERN       = /(\s*)~~SN \s+ (\w+)~~/x


#
# This mixin convertes a file path to the os Path representation
# todo maybe replace this by a builtin ruby stuff such as "pathname"
#
class String
  # convert the string to a path notation of the current operating system
  def to_osPath
    gsub(File::SEPARATOR, File::ALT_SEPARATOR || File::SEPARATOR)
  end

  # convert the string to a path notation of ruby.
  def to_rubyPath
    gsub(File::ALT_SEPARATOR || File::SEPARATOR, File::SEPARATOR)
  end

  # adding quotes around the string. Main purpose is to escape blanks
  # in file paths.
  def esc
    "\"#{self}\""
  end
end



#
# This class provides methods to tweak the reference according to the
# target document format
#
#
class ReferenceTweaker

  #This attribute keeps the target format
  attr_accessor :target, :log


  private

  # this prepares the reference in the target format
  #
  # :string: the Id of the referenced Traceable
  def prepareTraceReferences(string)
    result=string.gsub(/\s*/,"").split(",").map{|trace|
      itrace   = mkInternalTraceId(trace)
      texTrace = mkTexTraceDisplay(trace)
      if @target == "pdf" then
        "\\hyperlink{#{itrace}}{#{texTrace}}"
      else
        "[#{trace}](\##{itrace})"
      end
    }
    result.join(", ")
  end


  # this tweaks the reference-Id to be comaptible as TeX label
  # private methd
  def mkInternalTraceId(string)
    string.gsub("_","-")
  end

  # this tweaks the reference-id to be displayed in TeX
  # private method
  def mkTexTraceDisplay(trace)
    trace.gsub("_", "\\_")
  end

  public

  # constructor
  # :target: the target format
  #          in which the referneces shall be represented
  #todo: improve logger approach
  def initialize(target, logger=nil)
    @target=target

    @log=logger || $logger || nil

    if @log == nil
      @log = Logger.new(STDOUT)
      @log.level = Logger::INFO
      @log.datetime_format = "%Y-%m-%d %H:%M:%S"
      @log.formatter = proc do |severity, datetime, progname, msg|
        "#{datetime}: #{msg}\n"
      end
    end
  end

  # this does the postprocessing
  # of the file
  # in particluar handloe wortsammler's specific syntax.
  def prepareFile(infile, outfile)

    infileIo=File.new(infile)
    text = infileIo.readlines.join
    infileIo.close

    #include pdf files

    if @target == "pdf"
      text.gsub!(INCLUDE_PDF_PATTERN){|m|

        if $4
          pages="[pages=#{$4}]"
        else
          pages=""
        end

        if $5
          clearpage=$5
        else
          clearpage="cleardoublepage"
        end

        if $3.length > 0
          level=$3
        else
          level=9
        end

        "\n\n\\#{clearpage}\n\\bookmark[level=#{level},page=\\thepage]{#{$2}}\n\\includepdf#{pages}{#{$1}}"
      }
    else #if not pdf then it gets a regular external link
      text.gsub!(INCLUDE_PDF_PATTERN){|m|
        "[#{$2}](#{$1})"
      }
    end

    #inject the anchors for references to traces ->[traceid]
    if @target == "pdf" then
      text.gsub!(TRACE_ANCHOR_PATTERN){|m| "[#{$1}]#{$2}\\hypertarget{#{mkInternalTraceId($1)}}{}"}
    else
      text.gsub!(TRACE_ANCHOR_PATTERN){|m| "<a id=\"#{mkInternalTraceId($1)}\">[#{$1}]</a>#{$2}"}
    end

    #substitute arbitrary anchors for arbitrary targets <a id="">
    if @target == "pdf" then
      text.gsub!(ANY_ANCHOR_PATTERN){|m| "\\hypertarget{#{mkInternalTraceId($1)}}{}"}
    else
      # it is already html
    end

    #substitute arbitrary document internal references <a href=""></a>
    if @target == "pdf" then
      text.gsub!(ANY_REF_PATTERN){|m| "\\hyperlink{#{$1}}{#{mkTexTraceDisplay($2)}}"}
    else
      # it is already html
    end

    # substitute the uptrace references
    text.gsub!(UPTRACE_REF_PATTERN){|m| "}(#{prepareTraceReferences($1)})"}

    # substitute the informal trace references
    text.gsub!(TRACE_REF_PATTERN){|m| "[#{prepareTraceReferences($1)}]"}

    File.open(outfile, "w"){|f| f.puts(text)}
  end
end



#
# This class handles the configuration of WortSammler framework
#

class ProoConfig
  attr_reader :input,   # An array with the input filenames
    :outdir,              # directory where to place the output files
    :outname,             # basis to determine the output files
    :format,              # array of output formats
    :traceSortOrder,      # Array of strings to determine the sort ord
    :vars,                # hash of variables for pandoc
    :editions,            # hash of editions for pandoc
    :snippets,            # Array of strings to determine snippet filenames
    :upstream_tracefiles,  # Array of strings to determine upstream tracefile names
    :downstream_tracefile, # String to save downstram filename
    :reqtracefile_base,   # string to determine the requirements tracing results
    :frontmatter,          # Array of string to determine input filenames of frontmatter
    :rootdir,              # String directory of the configuration file
    :stylefiles            # Hash of stylefiles path to pandoc latex style file


  # constructor
  # @param [String] configFileName  name of the configfile (without .yaml)
  # @param [Symbol] configSelect Default configuration. If not specified
  #                 the very first entry in the config file
  #                 will apply.
  #                 TODO: not yet implemented.
  # @return [ProoConfig] instance
  def initialize(configFileName, configSelect=nil)
    begin
      config     = YAML.load(File.new(configFileName))
    rescue Exception => e
      unless File.exist?(configFileName) then
        $log.error "config file not found '#{configFileName}'"
      else
        $log.error "config file could not be loaded '#{configFileName}'"
        $log.error "reason '#{e.message}'"
      end
      exit(false)
    end

    basePath   = File.dirname(configFileName)

    # this makes an absolute path based on the absolute path
    # of the configuration file
    expand_path=lambda do |lf|
      File.expand_path("#{basePath}/#{lf}")
    end


    #activeConfigs=config.select{|x| [x[:name]] & ConfigSelet}

    selectedConfig=config.first
    #TODO: check the config file
    @input          = selectedConfig[:input].map{|file| File.expand_path("#{basePath}/#{file}")}
    @outdir         = File.expand_path("#{basePath}/#{selectedConfig[:outdir]}")
    @outname        = selectedConfig[:outname]
    @format         = selectedConfig[:format]
    @traceSortOrder = selectedConfig[:traceSortOrder]
    @vars           = selectedConfig[:vars] || {}
    @editions       = selectedConfig[:editions] || nil

    @downstream_tracefile = selectedConfig[:downstream_tracefile] || nil

    @reqtracefile_base    = selectedConfig[:reqtracefile_base] #todo expand path

    @upstream_tracefiles  = selectedConfig[:upstream_tracefiles] || nil
    @upstream_tracefiles  = @upstream_tracefiles.map{|file| File.expand_path("#{basePath}/#{file}")} unless @upstream_tracefiles.nil?
    @frontmatter   = selectedConfig[:frontmatter] || nil
    @frontmatter   = selectedConfig[:frontmatter].map{|file| File.expand_path("#{basePath}/#{file}")}  unless @frontmatter.nil?
    @rootdir        = basePath

    stylefiles     = selectedConfig[:stylefiles] || nil
    if stylefiles.nil?
      @stylefiles = {
        :latex => expand_path.call("../ZSUPP_Styles/default.latex"),
        :docx  => expand_path.call("../ZSUPP_Styles/default.docx"),
        :html  => expand_path.call("../ZSUPP_Styles/default.css")
      }
    else
      @stylefiles    = stylefiles.map{ |key,value| {key => expand_path.call(value)} }.reduce(:merge)
    end

    snippets       = selectedConfig[:snippets]
    if snippets.nil?
      @snippets       = nil
    else
      @snippets       = snippets.map{|file| File.expand_path("#{basePath}/#{file}")}
    end
  end
end


#
# This class provides the major functionalites
#
# Note that it is called PandocBeautifier for historical reasons
#
# provides methods to Process a pandoc file
#

class PandocBeautifier

  attr_accessor :log

  # the constructor
  # @param [Logger]  logger logger object to be applied.
  #                  if none is specified, a default logger
  #                  will be implemented

  def initialize(logger=nil)

    @view_pattern = /~~ED((\s*(\w+))*)~~/
    # @view_pattern = /<\?ED((\s*(\w+))*)\?>/
    @tempdir = Dir.mktmpdir

    @log=logger || $logger || nil

    if @log == nil
      @log = Logger.new(STDOUT)
      @log.level = Logger::INFO
      @log.datetime_format = "%Y-%m-%d %H:%M:%S"
      @log.formatter = proc do |severity, datetime, progname, msg|
        "#{datetime}: #{msg}\n"
      end

    end
  end

  # perform the beautify
  # * process the file with pandoc
  # * revoke some quotes introduced by pandoc
  # @param [String] file the name of the file to be beautified
  def beautify(file)

    @log.debug(" Cleaning: \"#{file}\"")

    docfile  = File.new(file)
    olddoc   = docfile.readlines.join
    docfile.close

    # process the file in pandoc
    cmd="pandoc -s #{file.esc} -f markdown -t markdown --atx-headers --reference-links "
    newdoc = `#{cmd}`
    @log.debug "beautify #{file.esc}: #{$?}"
    @log.debug(" finished: \"#{file}\"")

    # tweak the quoting
    if $?.success? then
      # do this twice since the replacement
      # does not work on e.g. 2\_3\_4\_5.
      #
      newdoc.gsub!(/(\w)\\_(\w)/, '\1_\2')
      newdoc.gsub!(/(\w)\\_(\w)/, '\1_\2')

      # fix more quoting
      newdoc.gsub!('-\\>[', '->[')

      # (RS_Mdc)
      # TODO: fix Table width toggles sometimes
      if (not olddoc == newdoc) then  ##only touch the file if it is really changed
        File.open(file, "w"){|f| f.puts(newdoc)}
        File.open(file+".bak", "w"){|f| f.puts(olddoc)} # (RS_Mdc_) # remove this if needed
        @log.debug("  cleaned: \"#{file}\"")
      else
        @log.debug("was clean: \"#{file}\"")
      end
      #TODO: error handling here
    else
      @log.error("error calling pandoc - please watch the screen output")
    end
  end


  # this replaces the text snippets in files
  def replace_snippets_in_file(infile, snippets)
    input_data = File.open(infile){|f| f.readlines.join}
    output_data=input_data.clone

    @log.debug("replacing snippets in #{infile}")

    replace_snippets_in_text(output_data, snippets)

    if (not input_data == output_data)
      File.open(infile, "w"){|f| f.puts output_data}
    end
  end

  # this replaces the snippets in a text
  def replace_snippets_in_text(text, snippets)
    changed=false
    text.gsub!(SNIPPET_PATTERN){|m|
      replacetext_raw=snippets[$2.to_sym]

      if replacetext_raw
        changed=true
        unless $1.nil? then
          leading_whitespace=$1.split("\n",100)
          leading_lines=leading_whitespace[0..-1].join("\n")
          leading_spaces=leading_whitespace.last || ""
          replacetext=leading_lines+replacetext_raw.gsub("\n", "\n#{leading_spaces}")
        end
        @log.debug("replaced snippet #{$2} with #{replacetext}")
      else
        replacetext=m
        @log.warn("Snippet not found: #{$2}")
      end
      replacetext
    }
    #recursively process nested snippets
    #todo: this approach might rais undefined snippets twice if there are defined and undefined ones
    replace_snippets_in_text(text, snippets) if changed==true
  end


  #
  # Ths determines the view filter
  #
  # @param [String] line - the current input line
  # @param [String] view - the currently selected view
  #
  # @return true/false if a view-command is found, else nil
  def get_filter_command(line, view)
    r = line.match(@view_pattern)

    if not r.nil?
      found = r[1].split(" ")
      result = (found & [view, "all"].flatten).any?
    else
      result = nil
    end

    result
  end

  #
  # This filters the document according to the target audience
  #
  # @param [String] inputfile name of inputfile
  # @param [String] outputfile name of outputfile
  # @param [String] view - name of intended view

  def filter_document_variant(inputfile, outputfile, view)

    input_data = File.open(inputfile){|f| f.readlines}

    output_data = Array.new
    is_active = true
    input_data.each{|l|
      switch=self.get_filter_command(l, view)
      l.gsub!(@view_pattern, "")
      is_active = switch unless switch.nil?
      @log.debug "select edtiion #{view}: #{is_active}: #{l.strip}"

      output_data << l if is_active
    }

    File.open(outputfile, "w"){|f| f.puts output_data.join }
  end

  #
  # This filters the document according to the target audience
  #
  # @param [String] inputfile name of inputfile
  # @param [String] outputfile name of outputfile
  # @param [String] view - name of intended view

  def process_debug_info(inputfile, outputfile, view)

    input_data = File.open(inputfile){|f| f.readlines }

    output_data = Array.new

    input_data.each{|l|
      l.gsub!(@view_pattern){|p|
        if $1.strip == "all" then
          color="black"
        else
          color="red"
        end

        "\\color{#{color}}\\rule{2cm}{0.5mm}\\marginpar{#{$1.strip}}"

      }

      l.gsub!(/todo:|TODO:/){|p| "#{p}\\marginpar{TODO}"}

      output_data << l
    }

    File.open(outputfile, "w"){|f| f.puts output_data.join }
  end


  # This compiles the input documents to one single file
  # it also beautifies the input files
  #
  # @param [Array of String] input - the input files to be processed in the given sequence
  # @param [String] output - the the name of the output file
  def collect_document(input, output)
    inputs=input.map{|xx| xx.esc.to_osPath }.join(" ")  # qoute cond combine the inputs
    inputname=File.basename(input.first)

    #now combine the input files
    @log.debug("combining the input files #{inputname} et al")
    cmd="pandoc -s -S -o #{output} --ascii #{inputs}" # note that inputs is already quoted
    system(cmd)
    if $?.success? then
      PandocBeautifier.new().beautify(output)
    end
  end

  #
  # This loads snipptes from xlsx file
  # @param [String] filename of the xlsx file
  # @return [Hash] a hash with the snippetes
  #
  def load_snippets_from_xlsx(file)
    temp_filename = "#{@tempdir}/snippett.xlsx"
    FileUtils::copy(file, temp_filename)
    wb=RubyXL::Parser.parse(temp_filename)
    result={}
    wb.first.each{|row|
      key, the_value = row
      unless key.nil?
        unless the_value.nil?
          result[key.value.to_sym] = resolve_xml_entities(the_value.value) rescue ""
        end
      end
    }
    result
  end

  #
  # this resolves xml entities in Text (lt, gt, amp)
  # @param [String] text with entities
  # @return [String] text with replaced entities
  def resolve_xml_entities(text)
    result=text
    result.gsub!("&lt;", "<")
    result.gsub!("&gt;", ">")
    result.gsub!("&amp;", "&")
    result
  end

  #
  # This generates the final document
  #
  # It actually does this in two steps:
  #
  # 1. process front matter to laTeX
  # 2. process documents
  #
  # @param [Array of String] input the input files to be processed in the given sequence
  # @param [String] outdir the output directory
  # @param [String] outname the base name of the output file. It is a basename in case the
  #                 output format requires multiple files
  # @param [Array of String] format list of formats which shall be generated.
  #                                 supported formats: "pdf", "latex", "html", "docx", "rtf", txt
  # @param [Hash] vars - the variables passed to pandoc
  # @param [Hash] editions - the editions to process; default nil - no edition processing
  # @param [Array of String] snippetfiles the list of files containing snippets
  # @param [String] file path to frontmatter the file to processed as frontmatter
  # @param [ProoConfig] config - the configuration file to be used
  def generateDocument(input, outdir, outname, format, vars, editions=nil, snippetfiles=nil, frontmatter=nil, config=nil)

    # combine the input files

    temp_filename    = "#{@tempdir}/x.md".to_osPath
    temp_frontmatter = "#{@tempdir}/xfrontmatter.md".to_osPath unless frontmatter.nil?
    collect_document(input, temp_filename)
    collect_document(frontmatter, temp_frontmatter)            unless frontmatter.nil?

    # process the snippets

    if not snippetfiles.nil?
      snippets={}
      snippetfiles.each{|f|
        if File.exists?(f)
          type=File.extname(f)
          case type
          when ".yaml"
            x=YAML.load(File.new(f))
          when ".xlsx"
            x=load_snippets_from_xlsx(f)
          else
            @log.error("Unsupported File format for snipptets: #{type}")
            x={}
          end
          snippets.merge!(x)
        else
          @log.error("Snippet file not found: #{f}")
        end
      }

      replace_snippets_in_file(temp_filename, snippets)
    end

    vars_frontmatter=vars.clone
    vars_frontmatter[:usetoc] = "nousetoc"


    if editions.nil?
      # there are no editions
      unless frontmatter.nil? then
        render_document(temp_frontmatter, tempdir, temp_frontmatter, ["frontmatter"], vars_frontmatter)
        vars[:frontmatter] = "#{tempdir}/#{temp_frontmatter}.latex"
      end
      render_document(temp_filename, outdir, outname, format, vars, config)
    else
      # process the editions
      editions.each{|edition_name, properties|
        edition_out_filename = "#{outname}_#{properties[:filepart]}"
        edition_temp_frontmatter = "#{@tempdir}/#{edition_out_filename}_frontmatter.md"  unless frontmatter.nil?
        edition_temp_filename = "#{@tempdir}/#{edition_out_filename}.md"
        vars[:title] = properties[:title]

        if properties[:debug]
          process_debug_info(temp_frontmatter, edition_temp_frontmatter, edition_name.to_s)  unless frontmatter.nil?
          process_debug_info(temp_filename, edition_temp_filename, edition_name.to_s)
          lvars=vars.clone
          lvars[:linenumbers] = "true"
          unless frontmatter.nil?                                                                # frontmatter
            lvars[:usetoc] = "nousetoc"
            render_document(edition_temp_frontmatter, @tempdir, "xfrontmatter", ["frontmatter"], lvars)
            lvars[:usetoc] = vars[:usetoc] || "usetoc"
            lvars[:frontmatter] = "#{@tempdir}/xfrontmatter.latex"
          end
          render_document(edition_temp_filename, outdir, edition_out_filename, ["pdf", "latex"], lvars, config)
        else
          unless frontmatter.nil?                                                                # frontmatter
            filter_document_variant(temp_frontmatter, edition_temp_frontmatter, edition_name.to_s)
            render_document(edition_temp_frontmatter, @tempdir, "xfrontmatter", ["frontmatter"], vars_frontmatter)
            vars[:frontmatter]="#{@tempdir}/xfrontmatter.latex"
          end
          filter_document_variant(temp_filename, edition_temp_filename, edition_name.to_s)
          render_document(edition_temp_filename, outdir, edition_out_filename, format, vars, config)
        end
      }
    end
  end

  #

  # render a single file
  # @param  input [String] path to the inputfile
  # @param  outdir [String] path to the output directory
  # @param  format [Array of String] formats
  # @return [nil] no useful return value
  def render_single_document(input, outdir, format)
    outname=File.basename(input, ".*")
    render_document(input, outdir, outname, format, {:geometry=>"a4paper"})
  end
  #
  # This renders the final document
  # @param [String] input the input file
  # @param [String] outdir the output directory
  # @param [String] outname the base name of the output file. It is a basename in case the
  #                 output format requires multiple files
  # @param [Array of String] format list of formats which shall be generated.
  #                                 supported formats: "pdf", "latex", "html", "docx", "rtf", txt
  # @param [Hash] vars - the variables passed to pandoc

  # @param  config [ProoConfig] the entire config object (for future extensions)
  # @return nil

  def render_document(input, outdir, outname, format, vars, config=nil)

    #TODO: Clarify the following
    # on Windows, Tempdir contains a drive letter. But drive letter
    # seems not to work in pandoc -> pdf if the path separator ist forward
    # slash. There are two options to overcome this
    #
    # 1. set tempdir such that it does not contain a drive letter
    # 2. use Dir.mktempdir but ensure that all provided file names
    #    use the platform specific SEPARATOR
    #
    # for whatever Reason, I decided for 2.

    tempfile     = input
    tempfilePdf  = "#{@tempdir}/x.TeX.md".to_osPath
    tempfileHtml = "#{@tempdir}/x.html.md".to_osPath
    outfilePdf   = "#{outdir}/#{outname}.pdf".to_osPath
    outfileDocx  = "#{outdir}/#{outname}.docx".to_osPath
    outfileHtml  = "#{outdir}/#{outname}.html".to_osPath
    outfileRtf   = "#{outdir}/#{outname}.rtf".to_osPath
    outfileLatex = "#{outdir}/#{outname}.latex".to_osPath
    outfileText  = "#{outdir}/#{outname}.txt".to_osPath
    outfileSlide = "#{outdir}/#{outname}.slide.html".to_osPath

    if vars.has_key? :frontmatter
      latexTitleInclude = "--include-before-body=#{vars[:frontmatter].esc}"
    else
      latexTitleInclude
    end

    #todo: make config required, so it can be reduced to the else part
    if config.nil? then
      latexStyleFile = File.dirname(File.expand_path(__FILE__))+"/../../resources/default.wortsammler.latex"
      latexStyleFile = File.expand_path(latexStyleFile).to_osPath
      css_style_file = File.dirname(File.expand_path(__FILE__))+"/../../resources/default.wortsammler.css"
      css_style_file = File.expand_path(css_style_file).to_osPath
    else
      latexStyleFile = config.stylefiles[:latex]
      css_style_file = config.stylefiles[:css]
    end


    toc = "--toc"
    toc = "" if vars[:usetoc]=="nousetoc"

    begin
      vars_string=vars.map.map{|key, value| "-V #{key}=#{value.esc}"}.join(" ")
    rescue
      require 'pry';binding.pry
    end

    @log.info("rendering  #{outname} as [#{format.join(', ')}]")

    begin

      if format.include?("pdf") then
        ReferenceTweaker.new("pdf").prepareFile(tempfile, tempfilePdf)
        cmd="pandoc -S #{tempfilePdf.esc} #{toc} --standalone --latex-engine xelatex --number-sections #{vars_string}" +
          " --template #{latexStyleFile.esc} --ascii -o  #{outfilePdf.esc} #{latexTitleInclude}"
        `#{cmd}`
      end



      if format.include?("frontmatter") then

        ReferenceTweaker.new("pdf").prepareFile(tempfile, tempfilePdf)

        cmd="pandoc -S #{tempfilePdf.esc}  --latex-engine xelatex  #{vars_string} --ascii -o  #{outfileLatex.esc}"
        `#{cmd}`
      end

      if format.include?("latex") then

        ReferenceTweaker.new("pdf").prepareFile(tempfile, tempfilePdf)

        cmd="pandoc -S #{tempfilePdf.esc} #{toc} --standalone  --latex-engine xelatex --number #{vars_string}" +
          " --template #{latexStyleFile.esc} --ascii -o  #{outfileLatex.esc} #{latexTitleInclude}"
        `#{cmd}`
      end

      if format.include?("html") then
        #todo: handle css
        ReferenceTweaker.new("html").prepareFile(tempfile, tempfileHtml)

        cmd="pandoc -S #{tempfileHtml.esc} --toc --standalone --self-contained --ascii --number-sections  #{vars_string}" +
          " -o #{outfileHtml.esc}"

        `#{cmd}`
      end

      if format.include?("docx") then
        #todo: handle style file
        ReferenceTweaker.new("html").prepareFile(tempfile, tempfileHtml)

        cmd="pandoc -S #{tempfileHtml.esc} #{toc} --standalone --self-contained --ascii --number  #{vars_string}" +
          " -o  #{outfileDocx.esc}"
        cmd="pandoc -S #{tempfileHtml.esc} --toc --standalone --self-contained --ascii --number-sections  #{vars_string}" +
          " -o  #{outfileDocx.esc}"
        `#{cmd}`
      end

      if format.include?("rtf") then

        ReferenceTweaker.new("html").prepareFile(tempfile, tempfileHtml)

        cmd="pandoc -S #{tempfileHtml.esc} --toc --standalone --self-contained --ascii --number-sections  #{vars_string}" +
          " -o  #{outfileRtf.esc}"
        `#{cmd}`
      end

      if format.include?("txt") then

        ReferenceTweaker.new("pdf").prepareFile(tempfile, tempfileHtml)

        cmd="pandoc -S #{tempfileHtml.esc} --toc --standalone --self-contained --ascii --number-sections  #{vars_string}" +
          " -t plain -o  #{outfileText.esc}"
        `#{cmd}`
      end

      if format.include?("slide") then

        ReferenceTweaker.new("slide").prepareFile(tempfile, tempfilePdf)
        #todo: hanlde stylefile
        cmd="pandoc -S #{tempfileHtml.esc} --toc --standalone --number #{vars_string}" +
          "  --ascii -t dzslides --slide-level 2 -o  #{outfileSlide.esc}"
        `#{cmd}`
      end
    rescue
      @log.error "failed to perform #{cmd}"
      #TODO make a try catch block kere
    end
    nil
  end

end
