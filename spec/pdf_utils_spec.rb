require 'wortsammler/pdf_utilities'
describe "pdf utilities:", :exp => false do


  before :all do
    @indir=File.dirname(__FILE__)
    @outdir=File.absolute_path("#{@indir}/../testoutput")
    @testbase="wortsammler_test"
    FileUtils.rm(Dir["#{@outdir}/#{@testbase}*.pdf"])
  end

  it "adjusts the bounding box of a pdf file" do
    pdffile="#{@testbase}_pdf.pdf"
    FileUtils.cp("#{@indir}/#{pdffile}", @outdir )
    Wortsammler.crop_pdf("#{@outdir}/#{pdffile}")

    Dir["#{@outdir}/#{@testbase}_pdf.pdf"].count.should==1
  end

  it "converts an excel sheet to pdf" do
    infile="#{@testbase}_xlsx.xlsx"
    @pdf_files = Wortsammler.xlsx_to_pdf("#{@indir}/#{infile}", "#{@outdir}/#{@testbase}_xlsx.pdf")

    Dir["#{@outdir}/#{@testbase}_xlsx*.pdf"].count.should==2
  end

  it "converts a powerpoint to pdf" do
    infile="#{@testbase}_pptx.pptx"
    outfile="#{@outdir}/#{@testbase}_pptx.pdf"
    Wortsammler.pptx_to_pdf("#{@indir}/#{infile}", outfile)
    Dir["#{@outdir}/#{@testbase}_pptx.pdf"].count.should==1
  end

  it "converts an excelsheet to cropped pdf" do
    infile="#{@testbase}_xlsx.xlsx"

    @pdf_files = Wortsammler.xlsx_to_cropped_pdf("#{@indir}/#{infile}", "#{@outdir}/#{@testbase}_xlsx_cropped.pdf")
    Dir["#{@outdir}/#{@testbase}_xlsx_cropped*.pdf"].count.should==2
  end

  it "converts a powerpoint to cropped pdf" do
    infile="#{@testbase}_pptx.pptx"
    outfile="#{@outdir}/#{@testbase}_pptx_cropped.pdf"
    Wortsammler.pptx_to_cropped_pdf("#{@indir}/#{infile}", outfile)
    Dir["#{@outdir}/#{@testbase}_pptx_cropped.pdf"].count.should==1
  end

end
