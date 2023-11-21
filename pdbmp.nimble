# Package

version       = "0.1.0"
author        = "Paul Straw"
description   = "BMP file parsing for Playdate"
license       = "MIT"
srcDir        = "src"
bin           = @["pdbmp"]


# Dependencies

requires "nim >= 1.6.16"

requires "playdate >= 0.11.2"

include playdate/build/nimble
