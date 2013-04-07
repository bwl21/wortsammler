
manifestfiles = Dir["ZSUPP_Manifest/*.yaml"]

manifestfiles.each{|file|
  desc "process #{file}"
  task file do
    cmd="wortsammler --compile #{file}"
    sh cmd
  end
}


task :default do |i|
  debugger
end
