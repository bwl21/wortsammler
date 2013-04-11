require 'rake'
require 'tmpdir'

wortsammlerbin = "'#{File.expand_path("bin")}'"
wortsammler    = "'#{File.expand_path(File.join("bin", "wortsammler"))}'"
testprojectdir = "testproject/30_Sources"

describe "Wortsammler generic issues" do

  it "provides a help" do
    result = `#{wortsammler} -h`
    result.should include("Usage: Wortsammler [options]")
    $?.success?.should==true
  end

  it "can create a new project folder" do
    system "#{wortsammler} -n #{testprojectdir}"
    $?.success?.should==true

    Dir["#{testprojectdir}/**/*"].should include "#{testprojectdir}/001_Main"
  end

  it "does not initialize into an existing project folder" do
    tempdir=Dir.mktmpdir
    `#{wortsammler} -n #{tempdir}`
    $?.success?.should==false
  end
end

describe "Wortsammler options validator" do
  it "rejects no processing" do
    system "#{wortsammler} -i."
    $?.success?.should==false
  end

  it "rejeccts inputs without outputs" do
    system "#{wortsammler} -pi ." do
      $?.success?.should==false
    end
  end
end

describe "Wortsammler beautifier features" do

  it "beautifies all markdown files in a folder" do
    tempdir=Dir.mktmpdir
    mdtext="#this is headline\n\n lorem ipsum\n\nbla fasel"

    cycles=10
    cycles.times{|i|
      File.open("#{tempdir}/#{i}.md", "w"){|f|f.puts mdtext}
    }

    system "#{wortsammler} -bi #{tempdir}"
    $?.success?.should==true

    cycles.times{|i|
      beautified_result=File.open("#{tempdir}/#{i}.md").readlines.join
      beautified_result.should include("# this is headline")
    }
  end

  it "claims undefined document path" do
    system "#{wortsammler} -bi this-path-does-not-exist"
    $?.success?.should == false
  end

  it "beautifies a single file" do
    tempdir=Dir.mktmpdir
    mdfile="#{tempdir}/single.md"
    mdtext="#this is headline\n\n lorem ipsum\n\nbla fasel"

    File.open(mdfile, "w"){|f|f.puts mdtext}
    system "#{wortsammler} -bi #{mdfile}"
    $?.success?.should==true

    beautified_result=File.open(mdfile).readlines.join
    beautified_result.should include("# this is headline")
  end

  it "claims missing input" do
    system "#{wortsammler} -b"
    $?.success?.should==false
  end

end

describe "Wortsammler conversion" do

  it "converts a single file to output format" do
    tempdir=Dir.mktmpdir
    mdfile="#{tempdir}/single.md"
    mdtext="#this is headline\n\n lorem ipsum\n\nbla fasel"
    File.open(mdfile, "w"){|f| f.puts mdtext}
    system "#{wortsammler} -pi #{mdfile} -o #{tempdir} -f latex:pdf:html:docx"
    $?.success?.should==true


    Dir["#{tempdir}/*"].map{|f|File.basename(f)}.should== ["single.docx",
                                                           "single.html",
                                                           "single.latex",
                                                           "single.md",
                                                           "single.pdf"
                                                           ]
  end

  it "converts all files within a folder output format" do
    tempdir=Dir.mktmpdir
    system "#{wortsammler} -pi . -o #{tempdir} -f latex:pdf:html:docx"
    $?.success?.should==true


    Dir["#{tempdir}/*"].map{|f|File.basename(f)}.should== ["main.docx",
                                                           "main.html",
                                                           "main.latex",
                                                           "main.pdf",
                                                           "README.docx",
                                                           "README.html",
                                                           "README.latex",
                                                           "README.pdf"]

  end

  it "processes a manifest" do
    FileUtils.cd("testproject/30_Sources/ZSUPP_Tools") {|d|
      manifest="../ZSUPP_Manifests/sample_the-sample-document.yaml"
      cmd= "#{wortsammler} -pm #{manifest}"
      system cmd
    }
    $?.success?.should==true
  end

  it "investigates the existence of a manifest" do
    manifest="testproject/30_Sources/ZSUPP_Manifests/xxthis-path-does-not-exist.yaml"
    system "#{wortsammler} -m #{manifest}"
    $?.success?.should==false
  end

  it "extracts the traceables according to a manifest" do
    manifest="testproject/30_Sources/ZSUPP_Manifests/sample_the-sample-document.yaml"
    system "#{wortsammler} -cm #{manifest}"
    $?.success?.should==true
  end


  # it "shall run the rake file in the sample document" do
  #   FileUtils.cd("testproject/30_Sources/ZSUPP_Tools") {|d|
  #     path=ENV['PATH']
  #     ENV['PATH']="#{wortsammlerbin}:#{path}"
  #     puts ENV['PATH']
  #     system 'wortsammler -h'
  #     #cmd= "rake sample"
  #     #system cmd
  #   }
  #   $?.success?.should==true
  # end
end
