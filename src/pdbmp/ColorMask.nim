import playdate/api

import byteSeq

type ColorMask* = seq[uint32]

proc parse*(
  self: var ColorMask,
  file: SDFile,
  filePath: string,
  maskDataOffset: int,
  maskColorCount: uint32
) =
  file.seek(maskDataOffset, SEEK_SET)

  for i in 0..<maskColorCount:
    self.add(file.read(4).bytes.toUint32())
