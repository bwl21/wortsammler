require 'rake'
require 'tmpdir'

wortsammler=File.join("bin", "wortsammler")

describe "Wortsammler" do

  it "shall provide a help" do
    result = `#{wortsammler} -h`
    result.should include("Usage: Wortsammler [options]")
    $?.success?.should==true

  end

  it "shall initialize a project" do
    system "#{wortsammler} --init testproject/30_Sources"
    $?.success?.should==true

    Dir["testproject/**/*"].should include "testproject/30_Sources/001_Main"
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
    FileUtils.cd("testproject/30_Sources/ZSUPP_Tools"){|d|
    manifest="../ZSUPP_Manifests/sample_the-sample-document.yaml"
    cmd= "../../../#{wortsammler} -pm #{manifest}"
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

end