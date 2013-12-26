# a=LatexHelper.new.set_command(cmd).setlogger(log).

class LatexHelper

  attr_accessor :latex_result, :mkindex_result

  @latex_command = nil
  @latex_result=nil
  @mkindex_result=nil
  @log=nil



  #
  # [initialize description]
  #
  # @return [type] [description]
  def initialize()
  end

  def setlogger(log)
    @log=log
    return self
  end



  #
  # [set_latex_command description]
  # @param  cmd [type] [description]
  #
  # @return [type] [description]
  def set_latex_command(cmd)
    @latex_command=cmd
    return self
  end


  #
  # [run_latex description]
  #
  # @return [type] [description]
  def run_latex()
    @latex_result = `#{@latex_command}`
    return self
  end

  #
  # [run_mkindex description]
  # @param  outfile [type] [description]
  #
  # @return [type] [description]
  def run_mkindex(outfile)
    outfilename=File.basename(outfile, ".*")
    indexinfile="#{outfilename}.idx"
    indexlogfile="#{outfilename}.ilg"
    indexoutfile="#{outfilename}.ind"

    current_dir = FileUtils.pwd
    FileUtils.cd(File.dirname(outfile)) do |mydir|
      @mkindex_result=nil
      if File.exist?(indexinfile) then
        a=`makeindex -q #{indexinfile.esc} 2>&1`
        @mkindex_result=ilg_analyse(indexlogfile)
      end
    end

    return self
  end


  #
  # [add_sort_key description]
  # @param  indexinfile [type] [description]
  #
  # @return [type] [description]
  def add_sort_key(indexinfile)
    content=File.open(indexinfile, "r").read
    content.gsub!(/\\indexentry{([^\}]*)}/){|entry|
      reference=$1.split("|").first
      originalterms=reference.split("!")
      newterms=originalterms.map{|ot|

        sortterm=ot.clone
        sortterm.gsub!('Ä', "ae")
        sortterm.gsub!('ä', "ae")
        sortterm.gsub!('Ö', "oe")
        sortterm.gsub!('ö', "oe")
        sortterm.gsub!('Ü', "ue")
        sortterm.gsub!('ü', "ue")
        sortterm.gsub!('ß', "ss")
        nt=ot
        nt="#{sortterm}@#{ot}" unless sortterm.include?("@")
      }.join("!")
      #      	require 'pry';binding.pry

      entry.gsub(reference, newterms)
    }

    File.open(indexinfile, "w") do |f|
      f.puts(content)
    end
  end

  #
  # [run description]
  # @param  outfile [type] [description]
  #
  # @return [type] [description]
  def run(outfile)

    reruncount=3

    run_latex()
    run_mkindex(outfile)

    while need_rerun? && ((reruncount-=1) >0)
      run_latex()
      run_mkindex(outfile)
    end
  end


  #
  # [need_rerun? description]
  #
  # @return [type] [description]
  def need_rerun?()
    @latex_result.include?("Rerun to get")
    true
  end


  #
  # [ilg_analyse description]
  # @param  logfilename [type] [description]
  #
  # @return [type] [description]
  def ilg_analyse(logfilename)
    stat = {}
    error = nil
    File.readlines(logfilename).each{ |logline|
      if error  #Index error announced in previous line
        ( stat[:errors] ||= [] ) << "#{logline.chomp.sub(/.*--/, "")} #{error}"
        error = nil
      else
        case logline
        when /Scanning input file (.*)\...done \((.*) entries accepted, (.*) rejected\)./
          #~ stat[:source_information] ||= [] << "input file #{$1} (#{$2} entries accepted, #{$3} rejected)"
          stat[:source_information] ||= []
          stat[:source_information] << "Input file: #{$1}"
          stat[:source_information] << "Entries accepted: #{$2}"
          stat[:source_information] << "Entries rejected: #{$3}"
          #~ when /done \((.*) entries accepted, (.*) rejected\)./
          #~ result[:rejected] += $2.to_i() if $2.to_i() > 0
        when /!! Input index error \(file = (.*), line = (.*)\):/
          #Error-message on next line
          error = "(file #{$1} line #{$2}: #{logline})"
        end
      end #if error
    }
    stat
  end


  # 
  # This analyzes the latex log file thereby filters warenings and errors
  # @param  logfilename [String] The filename of the log
  # 
  # @return [Nil] no return
  def log_analyze(logfilename)
    result = {
      errors: 0,
      warings: 0,
      loglines: []
    }

    outCounter = 0
    lineCounter = 0
    errorCounter = 0
    warningCounter = 0
    previousLine = ""

    logfilename_reported = File.basename(logfilename)

    File.readlines(logfilename).each{ |l|
      logline = l.strip
      lineCounter += 1


      if logline =~ /Output written on/ then
        outCounter = 5
      end

      if logline =~ /Running / then
        lineCounter = 0
      end

      if logline =~ /Buffer size exceeded/ then
        lineCounter = 0
        @log.error ("\n!Error Buffer size exceeded, for details see line #{lineCounter} #{logfilename_reported}")
        @log.info previousLine
        errorCounter += 1
        outCounter=5
      end

      if logline =~ /^!/ then
        lineCounter = 0
        @log.error ("LaTeX error; for details see line #{lineCounter} #{logfilename_reported}")
        errorCounter += 1
        outCounter=5
      end

      if logline =~ /\[ INFO\]/ then
        $log.info logline
      end

      if logline =~ /Warning:|pdfTeX warning/ then
        $log.warn "for details see line #{lineCounter} #{logfilename_reported}"
        warningCounter += 1
        outCounter = 5
      end

      if logline =~ /^(Underfull|Overfull)/  then
        outCounter = 0
      end

      if (outCounter > 0) then
        $log.info logline
        outCounter -= 1

        if outCounter == 0 then
          $log.info ""
        end
      end
    }

    @log.info ("logfilter: errors   = #{errorCounter}")
    @log.info ("logfilter: warnings = #{warningCounter}")

    errorCounter + warningCounter
  end

end
