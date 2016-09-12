require 'rake'
require 'tmpdir'
require 'pry'
require 'wortsammler.rb'

wortsammlerbin = "'#{File.expand_path("bin")}'"
wortsammler    = "'#{File.expand_path(File.join("bin", "wortsammler"))}'"
testprojectdir = "testproject/30_Sources"
specdir        = File.dirname(__FILE__)
testoutput     = "#{specdir}/../testoutput"


describe "Wortsammler generic issues" do

  it "provides a help", :exp => false do
    result = `#{wortsammler} -h`
    result.should include("Usage: Wortsammler [options]")
    $?.success?.should==true
  end

  it "runs silent", :exp => false do
    result = `#{wortsammler}`
    result.empty?.should==true
  end

  it "reports version numbers", :exp => false do
    result = `#{wortsammler} -v`
    result.should include "wortsammler"
    result.should include "pandoc"
    result.should include "XeTeX"
  end

  it "turns on vervbose mode", :exp => false do
    result = `#{wortsammler} -v`
    result.should include "DEBUG"
  end

  it "can create a new project folder", :exp => false do
    FileUtils.rm_rf(testprojectdir)
    system "#{wortsammler} -n #{testprojectdir}"
    $?.success?.should==true

    Dir["#{testprojectdir}/**/*"].should include "#{testprojectdir}/001_Main"
    Dir["#{testprojectdir}/**/snippets.xlsx"].should include "#{testprojectdir}/900_snippets/snippets.xlsx"
  end

  it "does not initialize into an existing project folder" do
    tempdir=Dir.mktmpdir
    `#{wortsammler} -n #{tempdir}`
    $?.success?.should==false
  end

  it "controls the pandoc options by document class" do
    pending "implement test to control pandoc options by document class"
  end
end

describe "Wortsammler options validator" do
  it "rejects no processing" do
    system "#{wortsammler} -i."
    $?.success?.should==false
  end


end

describe "Wortsammler beautifier features" do


  it "beautifies all markdown files in a folder" do
    tempdir=Dir.mktmpdir
    mdtext ="#this is headline\n\n lorem ipsum\n\nbla fasel"

    cycles=10
    cycles.times { |i|
      File.open("#{tempdir}/#{i}.md", "w") { |f| f.puts mdtext }
    }

    system "#{wortsammler} -bi #{tempdir}"
    $?.success?.should==true

    cycles.times { |i|
      beautified_result=File.open("#{tempdir}/#{i}.md").readlines.join
      beautified_result.should include("# this is headline")
    }
  end


  it "beautifies a single file", exp: false do
    tempdir=Dir.mktmpdir
    mdfile ="#{tempdir}/single.md"
    mdtext ="#this is headline\n\n lorem ipsum\n\nbla fasel"

    File.open(mdfile, "w") { |f| f.puts mdtext }
    system "#{wortsammler} -bi #{mdfile}"
    $?.success?.should==true

    beautified_result=File.open(mdfile).readlines.join
    beautified_result.should include("# this is headline")
  end

  it "recognizes if the specified manifest file is a directory", exp: false do
    FileUtils.cd("testproject/30_Sources/ZSUPP_Tools") { |d|
      manifest="../ZSUPP_Manifests"
      cmd     = "#{wortsammler} -bm #{manifest} 2>&1"
      r       =`#{cmd}`
      r.include?("directory").should==true
    }
    $?.success?.should==false
  end
  it "beautifies input files in a manifest" do
    FileUtils.cd("testproject/30_Sources/ZSUPP_Tools") { |d|
      manifest = "../ZSUPP_Manifests/sample_the-sample-document.yaml"
      cmd      = "#{wortsammler} -bm #{manifest}"
      system cmd
    }
    $?.success?.should==true
  end

  it "claims missing input" do
    system "#{wortsammler} -b"
    $?.success?.should==false
  end


  it "claims undefined document path" do
    system "#{wortsammler} -bi this-path-does-not-exist"
    $?.success?.should == false
  end

  it "creates a semantically unchanged markdown file", exp: false do
    testname      = 'test_beautify'
    inputfile     = %Q{#{specdir}/#{testname}.md}
    outputfile    = %Q{#{testoutput}/#{testname}.md}
    referencefile = %Q{#{specdir}/#{testname}_reference.md}

    FileUtils.cp(inputfile, outputfile)
    cmd = "#{wortsammler} -bi '#{outputfile}'"
    system cmd

    reference = File.open(referencefile).read
    result    = File.open(outputfile).read
    result.should == reference
  end

end

describe "Wortsammler conversion" do

  it "converts a single file to output format" do
    tempdir=Dir.mktmpdir
    mdfile ="#{tempdir}/single.md"
    mdtext ="#this is headline\n\n lorem ipsum\n\nbla fasel"
    File.open(mdfile, "w") { |f| f.puts mdtext }
    system "#{wortsammler} -pi #{mdfile} -o #{tempdir} -f latex:pdf:html:docx"
    $?.success?.should==true


    Dir["#{tempdir}/*"].map { |f| File.basename(f) }.should== ["single.docx",
                                                               "single.html",
                                                               "single.latex",
                                                               "single.log",
                                                               "single.md",
                                                               "single.pdf"
    ]
  end

  it "converts a single file to default output format" do
    tempdir=Dir.mktmpdir
    mdfile ="#{tempdir}/single.md"
    mdtext ="#this is headline\n\n lorem ipsum\n\nbla fasel"
    File.open(mdfile, "w") { |f| f.puts mdtext }
    system "#{wortsammler} -pi #{mdfile} -o #{tempdir}"
    $?.success?.should==true


    Dir["#{tempdir}/*"].map { |f| File.basename(f) }.should== ["single.log",
                                                               "single.md",
                                                               "single.pdf"
    ]
  end


  it "handles chapters up to 6 levels", exp: false do
    tempdir="#{specdir}/../testoutput"
    mdfile ="#{tempdir}/chapternesting.md"
    mdtext ="#this is headline\n\n lorem ipsum\n\nbla fasel"

    def lorem(j)
      (1.upto 100).map { |i| "text_#{j} lorem ipsum #{i} dolor " }.join(" ")
    end

    def chapter(i, depth)
      ["\n\n", "##########"[1..depth], " this is example on level  #{i} .. #{depth}\n\n",
       lorem(i),
      ].join("")
    end

    File.open(mdfile, "w") { |f|
      1.upto 10 do |i|
        1.upto 6 do |j|
          f.puts chapter(i, j)
        end
      end
    }

    system "#{wortsammler} -pbi '#{mdfile}' -o '#{tempdir}' -f pdf:latex"
    $?.success?.should==true

    Dir["#{tempdir}/chapternesting*"].map { |f| File.basename(f) }.sort.should== ["chapternesting.md",
                                                                                  "chapternesting.pdf",
                                                                                  "chapternesting.latex",
                                                                                  "chapternesting.log",
                                                                                  "chapternesting.md.bak"
    ].sort
  end

  it "handles lists up to 9 levels", exp: false do
    tempdir="#{specdir}/../testoutput"
    mdfile ="#{tempdir}/listnesting.md"
    mdtext ="#this is headline\n\n lorem ipsum\n\nbla fasel"

    def lorem(j)
      (1.upto 100).map { |i| "text_#{j} lorem ipsum #{i} dolor " }.join(" ")
    end

    def chapter(i, depth)
      ["\n\n", "##########"[1..depth], " this is example on level  #{i} .. #{depth}\n\n",
       lorem(i),
      ].join("")
    end

    File.open(mdfile, "w") { |f|
      f.puts "# depth test for lists"
      f.puts ""
      f.puts lorem(1)
      f.puts ""

      0.upto 8 do |i|
        f.puts ["    "*i, "-   this is list level #{i}"].join
      end
    }

    system "#{wortsammler} -pbi '#{mdfile}' -o '#{tempdir}' -f pdf:latex"
    $?.success?.should==true

    Dir["#{tempdir}/listnesting*"].map { |f| File.basename(f) }.sort.should== ["listnesting.md",
                                                                               "listnesting.pdf",
                                                                               "listnesting.latex",
                                                                               "listnesting.log",
                                                                               "listnesting.md.bak"
    ].sort
  end

  it "converts all files within a folder to output format" do
    tempdir   =Dir.mktmpdir
    mdtext    ="# Header\n\n lorem ipsum\n"
    basefiles = ["f1", "f2", "f3"]
    outfiles  = basefiles.map { |f| ["#{f}.md", "#{f}.latex"] }.flatten.sort
    basefiles.each { |f|
      File.open("#{tempdir}/#{f}.md", "w") { |fo| fo.puts mdtext }
    }

    system "#{wortsammler} -pi #{tempdir} -o #{tempdir} -f latex"
    $?.success?.should==true

    Dir["#{tempdir}/*"].map { |f| File.basename(f) }.sort.should== outfiles

  end

  it "processes a manifest" do
    FileUtils.cd("testproject/30_Sources/ZSUPP_Tools") { |d|
      manifest="../ZSUPP_Manifests/sample_the-sample-document.yaml"
      cmd     = "#{wortsammler} -pm #{manifest}"
      system cmd
    }
    $?.success?.should==true
  end

  it "investigates the existence of a manifest" do
    manifest="testproject/30_Sources/ZSUPP_Manifests/xxthis-path-does-not-exist.yaml"
    system "#{wortsammler} -m #{manifest}"
    $?.success?.should==false
  end

  it "extracts the traceables according to a manifest", :exp => false do
    manifest="testproject/30_Sources/ZSUPP_Manifests/sample_the-sample-document.yaml"
    system "#{wortsammler} -cm #{manifest}"
    $?.success?.should==true
  end


  it "extracts plantuml according to a manifest", :exp => false do
    manifest="testproject/30_Sources/ZSUPP_Manifests/sample_the-sample-document.yaml"
    system "#{wortsammler} -um #{manifest}"
    $?.success?.should==true
  end

  it "extracts plantuml from a single file", :exp => false do
    outfile="#{testoutput}/authentification.png"
    FileUtils.rm(outfile) if File.exists?(outfile)
    system "#{wortsammler} -ui \"#{specdir}/TC_EXP_002.md\""
    $?.success?.should==true
    File.exist?(outfile).should==true
  end

  it "extracts plantuml from a folder", :exp => false do
    outfile="#{testoutput}/authentification.png"
    FileUtils.rm(outfile) if File.exists?(outfile)
    system "#{wortsammler} -ui \"#{specdir}\""
    $?.success?.should==true
    File.exist?(outfile).should==true
  end


  it "processes snippets" do
    pending "Test not yet implemented"
  end

  it "handles undefined snippets" do
    pending "Test not yet implemented"
  end


  it "runs the rake file in the sample document", exp: false do
    FileUtils.cd("testproject/30_Sources/ZSUPP_Tools") { |d|
      path        = ENV['PATH']
      ENV['PATH'] = "#{wortsammlerbin}:#{path}"
      puts ENV['PATH']
      #system 'wortsammler -h'
      cmd = "rake sample"
      system cmd
    }
    Dir["testproject/30_Sources/ZGEN_Documents/*.*"].count.should==15
    $?.success?.should==true
  end

  it "compiles all documents", exp: false do
    FileUtils.cd("testproject/30_Sources/ZSUPP_Tools") { |d|
      path       =ENV['PATH']
      ENV['PATH']="#{wortsammlerbin}:#{path}"
      puts ENV['PATH']
      #system 'wortsammler -h'
      cmd= "rake all"
      #system cmd
    }
  end

end

describe "Wortsammler output formats" do


  it "generates dzslides", exp: false do
    mdfile = %Q{'#{specdir}/test_slides.md'}
    FileUtils.cd("spec") do
      system %Q{#{wortsammler} -pi #{mdfile} -o '#{testoutput}' -f slidy}
    end
  end


  it "generates beamer files", exp: false do
    mdfile = %Q{'#{specdir}/test_slides.md'}
    FileUtils.cd("spec") do
      system %Q{#{wortsammler} -pi #{mdfile} -o '#{testoutput}' -f beamer}
    end
  end


  it "generates markdown", exp: true do

  end
end


describe "Wortsammler syntax extensions", :exp => false do
  it "[RS_Comp_012] supports embedded images" do
    tempdir   ="#{specdir}/../testoutput"
    imagefile ="floating-image.pdf"

    FileUtils.cd(tempdir) { |c|
      FileUtils.cp("#{specdir}/#{imagefile}", ".")

      mdfile="embedded-image.md"

      mdtext=["#this is headline",
              (5..100).to_a.map { |oi|
                ["\n\n",
                 "this is image\n\n~~EMBED \"#{imagefile}\" o 40mm 60mm~~",
                 (1..20).to_a.map { |ii|
                   "#{oi} und #{ii} lorem ipsum und blafasel"
                 }.join(" "),
                 "\n\n",
                 (5..15+oi).to_a.map { |ii|
                   "#{oi} und #{ii} lorem ipsum und blafasel"
                 }.join(" "),
                 "\n\n"]
              }
      ].flatten.join("\n")

      File.open(mdfile, "w") { |f| f.puts mdtext }

      system "#{wortsammler} -pi '#{mdfile}' -o '.' -f pdf:latex:html:docx"
      FileUtils.rm imagefile
    }
    $?.success?.should==true
  end

  it "TC_EXP_001 expands expected results from testcases", exp: false do

    proc    = ReferenceTweaker.new("pdf")
    outfile = "#{specdir}/../testoutput/TC_EXP_001.output.md"
    File.unlink(outfile) if File.exists?(outfile)
    proc.prepareFile("#{specdir}/TC_EXP_001.md", outfile)

    a=File.open(outfile, "r").readlines.join
    a.should include("TC-DES-003-01")
  end

  it "TC_EXP_002 removes plantuml sources", exp: false do

    proc    = ReferenceTweaker.new("pdf")
    outfile = "#{specdir}/../testoutput/TC_EXP_002.output.md"
    File.unlink(outfile) if File.exists?(outfile)
    proc.prepareFile("#{specdir}/TC_EXP_002.md", outfile)

    a = File.open(outfile, "r").readlines.join
    a.include?(".plantuml").should==false
  end

  it "TC_EXP_003 handles Markdown inlays", exp: true do
    tempdir       ="#{specdir}/../testoutput"
    mdinlayfile   ="TC_EXP_003_1.md"
    mdinlayfile_1 ="TC_EXP_003_2.md"
    mdfile        ="tc_exp_003"

    FileUtils.cd(tempdir) { |c|
      FileUtils.cp("#{specdir}/#{mdinlayfile}", ".")
      FileUtils.cp("#{specdir}/#{mdinlayfile_1}", ".")


      mdtext=["#this is headline",
              "",
              "~~~~",
              "", "now verbatim by indent inclucde #{mdinlayfile}", "",
              "    ~~MD \"#{mdinlayfile}\"~~",
              "~~~~",
              "",
              "", "now full format inclucde #{mdinlayfile}", "",
              "~~MD \"#{mdinlayfile}\"~~",
              "",
              "", "now full format inclucde #{mdinlayfile_1}", "",
              "~~MD \"#{mdinlayfile_1}\"~~",
      ].flatten.join("\n")

      File.open("#{mdfile}.md", "w") { |f| f.puts mdtext }

      system "#{wortsammler} -pi '#{mdfile}.md' -o '.' -f txt"
      FileUtils.rm mdinlayfile
      FileUtils.rm mdinlayfile_1
    }

    ref    = File.open("#{specdir}/tc_exp_003_reference.txt").read
    result = File.open("#{tempdir}/#{mdfile}.txt").read
    ref.should==result
  end

  it "generates an index", exp: false do
    system "wortsammler -pi \"#{specdir}/test_mkindex.md\" -f pdf:latex -o \"#{testoutput}\""
    system "pdftotext \"#{testoutput}/test_mkindex.pdf\""
    the_time = Time.now.strftime("%B %d, %Y")
    ref      = File.open("#{specdir}/test_mkindex_reference.txt").read
    result   = File.open("#{testoutput}/test_mkindex.txt").read
    result   = result.gsub(the_time, "December 17, 2014")
    result.should==ref
  end

  it "reports TeX messages", exp: false do
    system %Q{wortsammler -pi '#{specdir}/test_mkindex.md' -f pdf:latex -o '#{testoutput}' >> '#{testoutput}/test_mkindex.lst'}
    system "pdftotext \"#{testoutput}/test_mkindex.pdf\""
    result = File.open("#{testoutput  }/test_mkindex.lst").read
    result.include?("[WARN]").should==true
  end


end