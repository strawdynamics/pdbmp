# Package

version       = "0.1.0"
author        = "Paul Straw"
description   = "pdbmp_02_normal"
license       = "MIT"
srcDir        = "src"
bin           = @["pdbmp_02_normal"]


# Dependencies

requires "nim >= 1.6.16"

requires "playdate >= 0.11.2"

include playdate/build/nimble
include ../../src/build/nimble
