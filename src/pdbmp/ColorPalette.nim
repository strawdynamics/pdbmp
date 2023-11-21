import playdate/api

import Color
import byteSeq

type ColorPalette* = seq[Color]

proc parse*(
  self: var ColorPalette,
  file: SDFile,
  filePath: string,
  paletteDataOffset: int,
  paletteColorCount: uint32
) =
  file.seek(paletteDataOffset, SEEK_SET)

  for i in 0..<paletteColorCount:
    self.add(file.read(4).bytes.bgraToColor())
