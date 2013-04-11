
##
#
# (c) 2013 Bernhard Weichel
#
#


##
# generate a task for each manifest file
#
Dir["../ZSUPP_Manifests/*.yaml"].each{|file|
  taskdesc=File.basename(file, ".yaml")
  taskname=taskdesc.split("_")[0]
  desc "generate #{taskdesc}"
  task taskname do
    cmd="wortsammler -cbpm #{file}"
    sh cmd
  end
}

##
# the default task

desc "print this help"
task :default do
  system "rake -T"
end
