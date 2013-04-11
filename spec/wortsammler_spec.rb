require 'rake'
require 'tmpdir'

wortsammlerbin = "'#{File.expand_path("bin")}'"
wortsammler    = "'#{File.expand_path(File.join("bin", "wortsammler"))}'"
testprojectdir = "testproject/30_Sources"

describe "Wortsammler" do

  it "shall provide a help" do
    result = `#{wortsammler} -h`
    result.should include("Usage: Wortsammler [options]")
    $?.success?.should==true

  end

  it "shall initialize a project" do
    system "#{wortsammler} --init #{testprojectdir}"
    $?.success?.should==true

    Dir["#{testprojectdir}/**/*"].should include "#{testprojectdir}/001_Main"
  end

  it "shall not initialize to an existing directory" do
    tempdir=Dir.mktmpdir
    `#{wortsammler} --init #{tempdir}`
    $?.success?.should==false
  end

  it "shall beautify all markdown files in a folder" do
    tempdir=Dir.mktmpdir
    mdtext="#this is headline\n\n lorem ipsum\n\nbla fasel"

    cycles=10
    cycles.times{|i|
      File.open("#{tempdir}/#{i}.md", "w"){|f|f.puts mdtext}
    }

    system "#{wortsammler} --beautify_path #{tempdir}"
    $?.success?.should==true

    cycles.times{|i|
      beautified_result=File.open("#{tempdir}/#{i}.md").readlines.join
      beautified_result.should include("# this is headline")
    }
  end

  it "shall claim undefined document path" do
    system "#{wortsammler} -b this-path-does-not-exist"
    $?.success?.should == false
  end

  it "shall beautify a single file in a folder" do
    tempdir=Dir.mktmpdir
    mdfile="#{tempdir}/single.md"
    mdtext="#this is headline\n\n lorem ipsum\n\nbla fasel"

    File.open(mdfile, "w"){|f|f.puts mdtext}
    system "#{wortsammler} -b #{mdfile}"
    $?.success?.should==true

    beautified_result=File.open(mdfile).readlines.join
    beautified_result.should include("# this is headline")
  end

  it "shall convert a single file" do
    tempdir=Dir.mktmpdir
    mdfile="#{tempdir}/single.md"
    mdtext="#this is headline\n\n lorem ipsum\n\nbla fasel"

    system "#{wortsammler} -i #{mdfile} -f PDF:DOCX"
    $?.success?.should==true

  end

  it "shall process a manifest" do
    FileUtils.cd("testproject/30_Sources/ZSUPP_Tools") {|d|
      manifest="../ZSUPP_Manifests/sample_the-sample-document.yaml"
      cmd= "#{wortsammler} -pm #{manifest}"
      system cmd
    }
    $?.success?.should==true
  end

  it "shall investigate the existence of a manifest" do
    manifest="testproject/30_Sources/ZSUPP_Manifests/xxthis-path-does-not-exist.yaml"
    system "#{wortsammler} -m #{manifest}"
    $?.success?.should==false
  end

  it "shall extract the traceables according to a manifest" do
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
