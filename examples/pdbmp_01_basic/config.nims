# begin Nimble config (version 2)
when withDir(thisDir(), system.fileExists("nimble.paths")):
  include "nimble.paths"
# end Nimble config

# Copy shared test bmp files
rmDir("source/bmp")
cpDir("../../bmp", "source/bmp")

# FIXME: This causes duplicate symbol build errors
# include playdate/build/config
