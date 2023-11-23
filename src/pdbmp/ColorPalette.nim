import playdate/api

import Color
import byteSeq

type ColorPalette* = seq[Color]

proc parse*(
  self: var ColorPalette,
  file: SDFile,
  filePath: string,
  paletteDataOffset: int,
  paletteColorCount: uint32,
  paletteEntrySize: uint
) =
  file.seek(paletteDataOffset, SEEK_SET)

  for i in 0..<paletteColorCount:
    let color = if paletteEntrySize == 3:
      file.read(3).bytes.bgrToColor()
    else:
      file.read(4).bytes.bgraToColor()

    self.add(color)
