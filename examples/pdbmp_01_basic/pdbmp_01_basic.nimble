# Package

version       = "0.1.0"
author        = "Paul Straw"
description   = "pdbmp_01_basic"
license       = "MIT"
srcDir        = "src"
bin           = @["pdbmp_01_basic"]


# Dependencies

requires "nim >= 1.6.16"

requires "playdate >= 0.11.2"

include playdate/build/nimble
