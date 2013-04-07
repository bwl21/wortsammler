##
#
# (c) 2013 Bernhard Weichel
#
#

def wortsammler_init_folders(root)

  folders=["ZSUPP_Manifests",
           "ZGEN_Documents",
           "ZSUPP_Tools",
           "ZSUPP_Styles",
           "001_Main"
           ]

  folders.each{|folder|
    FileUtils.mkdir_p("#{root}/#{folder}")
  }

end
