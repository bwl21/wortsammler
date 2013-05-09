require 'wortsammler/class.proolib.rb'

describe PandocBeautifier do
  it "checks the availability of the right pandoc version", :exp=> false do

    PandocBeautifier.new.check_pandoc_version.should == true
  end
end
