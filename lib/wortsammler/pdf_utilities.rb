require 'tmpdir'
require 'fileutils'

#
# 

# 
# This module provides utilites to handle pdf file.s
# 
# Note that it only works on Mac OS X.
# 
# @author [Bernhard Weichel]
# 
module Wortsammler

  # 
  # convert an excel workbook to cropped pdf file.
  # it generates one file per sheet
  #  
  # @param  infile [String] name of the Excel file
  # @param  outfile [String] basis of the generated pdf file. The name of the
  #         sheet is mangled into the file accroding to the pattern
  #         <body_of_outfile> <name of the sheet>.<extension of outfile>
  #         note the space inserted by excel.
  # 
  # @return [Array of String] the list of generated files.
  # 
  def self.xlsx_to_cropped_pdf(infile, outfile)
    outfiles=self.xlsx_to_pdf(infile, outfile)
    outfiles.each{|f|
      self.crop_pdf(f)
    }

    outfiles
  end


  # 
  # convert an excel workbook to *non cropped* pdf file.
  # it generates one file per sheet
  #  
  # @param  infile [String] name of the Excel file
  # @param  outfile [String] basis of the generated pdf file. The name of the
  #         sheet is mangled into the file accroding to the pattern
  #         <body_of_outfile> <name of the sheet>.<extension of outfile>
  #         note the space inserted by excel.
  # 
  # @return [Array of String] the list of generated files.
  # 
  def self.xlsx_to_pdf(infile, outfile)

    tmpdir=Dir.mktmpdir
    outext=File.extname(outfile)
    tmpbase=File.basename(outfile, outext)
    tmpfile="#{tmpdir}/#{File.basename(infile)}"
    outdir =File.dirname(File.absolute_path(outfile))

    FileUtils.cp(infile, tmpfile)

    cmd=[]
    cmd << "osascript <<-EOF"
    cmd << "tell application \"Microsoft Excel\""
    #cmd << "activate"
    cmd << ""
    cmd << "open \"#{tmpfile}\""
    cmd << ""
    cmd << "save active workbook in \"#{tmpbase}.pdf\" as PDF file format"
    cmd << "close workbook 1 saving no"
    cmd << "delay 5"
    cmd << "quit"
    cmd << "end tell"
    cmd = cmd.join("\n")
    system(cmd)

    Dir["#{tmpdir}/#{tmpbase}*.pdf"].each do |f|
      outfilename=File.basename(f).gsub(" ", "_")
      FileUtils.cp(f, "#{outdir}/#{outfilename}")
    end

    Dir["#{outdir}/#{tmpbase}*#{outext}"]
  end


  # 
  # convert an Powerpoint presentation to cropped pdf file.
  # it generates one file per sheet
  #  
  # @param  infile [String] name of the Powerpoint file
  # @param  outfile [String] basis of the generated pdf file. 
  # 
  # @return [Array of String] the list of generated files. In fact it
  #         it is only one file. But for sake of harmonization with 
  #         xlsx_to_pdf it is returned as an array.
  # 
  def self.pptx_to_cropped_pdf(infile, outfile)
    outfiles=self.pptx_to_pdf(infile, outfile)
    outfiles.each{|f|
      self.crop_pdf(f)
    }
    outfile
  end

  # 
  # convert an Powerpoint presentation to non cropped pdf file.
  # it generates one file per sheet
  #  
  # @param  infile [String] name of the Powerpoint file
  # @param  outfile [String] basis of the generated pdf file. 
  # 
  # @return [Array of String] the list of generated files. In fact it
  #         it is only one file. But for sake of harmonization with 
  #         xlsx_to_pdf it is returned as an array.
  # 
  def self.pptx_to_pdf(infile, outfile)

    tmpdir=Dir.mktmpdir
    tmpout="#{tmpdir}/#{File.basename(outfile)}"
    tmpin="#{tmpdir}/#{File.basename(infile)}"
    outdir =File.dirname(File.absolute_path(outfile))

    FileUtils.cp(infile, tmpin)

    cmd=[]
    cmd << "osascript <<-EOF"
    cmd << "tell application \"Microsoft PowerPoint\""
    #cmd << "activate"
    cmd << ""
    cmd << "open \"#{tmpin}\""
    cmd << "open \"#{tmpin}\"" # todo: I open it twice making sure that it is really open
    cmd << "set theActivePPT to the active presentation"
    cmd << "save theActivePPT in \"#{tmpout}\" as save as PDF"
    cmd << "close theActivePPT"
    cmd << "quit"
    cmd << "end tell"
    cmd = cmd.join("\n")
    system(cmd)
    FileUtils.cp("#{tmpout}", outfile)
    [outfile]
  end


  # 
  # crop a pdf file
  # @param  infile [String] The name of the pdf file
  # @param  outfile [String] The name of the output file.
  #         if no file is given, then the inputfile is
  #         replaced by the cropped file.   
  # 
  # @return [nil] no return
  # 
  def self.crop_pdf(infile, outfile=nil)

    result=`gs -q -dBATCH -dNOPAUSE -sDEVICE=bbox \"#{infile}\" 2>&1`
    coords=/%BoundingBox:\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)/.match(result).captures.join(" ")

    tmpfile=infile+"_tmp"

    cmd =[]
    cmd << "gs -q -dBATCH -dNOPAUSE -sDEVICE=pdfwrite"
    cmd << "-o\"#{tmpfile}\""
    cmd << "-c \"[/CropBox [#{coords}] /PAGES pdfmark\""
    cmd << "-f \"#{infile}\""
    cmd = cmd.join(" ")
    result = system(cmd)

    outfile=infile if outfile.nil?
    FileUtils.cp(tmpfile, outfile)
    FileUtils.rm(tmpfile)
    nil
  end

end
