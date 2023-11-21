import playdate/api

import pdbmp/byteSeq
import pdbmp/Color
import pdbmp/ColorPalette
import pdbmp/DibHeader
import pdbmp/util

type PdBmp* = ref object
  filePath*: string
  file: SDFile
  fileSize: uint32
  pixelDataOffset: uint32
  dibHeader*: DibHeader
  colorPalette*: ColorPalette

# "BM"
const expectedMagicBytes = @[0x42'u8, 0x4d'u8]

proc printFilePath*(self: PdBmp) =
  log("printfilepath " & self.filePath)

proc openFile(self: var PdBmp) =
  self.file = playdate.file.open(self.filePath, FileOptions.kFileRead)

proc parseFileHeader(self: var PdBmp) =
  self.file.seek(0, SEEK_SET)

  # Check magic bytes
  let magic = self.file.read(2)
  if magic.bytes != expectedMagicBytes:
    raise IOError.newException("Unknown magic bytes " & $(magic.bytes))

  # Read file size
  self.fileSize = self.file.read(4).bytes.toUint32()
  # Skip 4 reserved bytes
  self.file.seek(4, SEEK_CUR)
  # Read pixel data offset
  self.pixelDataOffset = self.file.read(4).bytes.toUint32()

  # log("fsbytes: " & $(self.fileSize))
  # log("pxdataoffset: " & $(self.pixelDataOffset))

proc parseDibHeader(self: PdBmp) =
  self.dibHeader = DibHeader()
  self.dibHeader.parse(self.file, self.filePath)

proc parseColorPalette(self: PdBmp) =
  if not self.dibHeader.hasPalette:
    return

  self.colorPalette = @[]
  self.colorPalette.parse(
    self.file,
    self.filePath,
    self.dibHeader.paletteDataOffset,
    self.dibHeader.usedColorsCount
  )

proc parse*(self: var PdBmp) =
  self.openFile()

  self.parseFileHeader()

  self.parseDibHeader()

  self.parseColorPalette()

  self.file.close()
  self.file = nil

# proc sample(pdBmp: PdBmp, x: int32, y: int32): void =
#   # TODO: also the type
