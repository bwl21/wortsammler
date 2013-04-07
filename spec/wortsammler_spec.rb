require 'rake'

describe "Wortsammler" do

	it "shall provide a help" do 
		result = `wortsammler -h`
		result.should=="  This is Wortsammler\n    \n  Usage: Wortsammler [options] \n    \n    -h, --help                       Display this screen\n    -v, --verbose                    Output more information on stdout\n    -i, --init DIR                   create a project folder\n"
	end
	
	it "shall initialize a project" do
		system "wortsammler --init testproject/30_Sources"

		Dir["testproject/**/*"].should== ["testproject/30_Sources", "testproject/30_Sources/001_Main", "testproject/30_Sources/ZGEN_Documents", "testproject/30_Sources/ZSUPP_Manifests", "testproject/30_Sources/ZSUPP_Styles", "testproject/30_Sources/ZSUPP_Tools"]
	end

end