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
  pixelData: seq[byte]

# "BM"
const expectedMagicBytes = @[0x42'u8, 0x4d'u8]

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

proc readPixelData(self: PdBmp) =
  self.file.seek(int(self.pixelDataOffset), SEEK_SET)
  self.pixelData = self.file.read(self.dibHeader.imageDataSize).bytes

proc parse*(self: var PdBmp) =
  self.openFile()

  self.parseFileHeader()

  self.parseDibHeader()

  self.parseColorPalette()

  self.readPixelData()

  self.file.close()
  self.file = nil

# TODO: Raise if x, y out of range
# TODO: By default, origin is top left, _unlike_ BMP (bottom left). If imageHeight is negative, BMP origin _is_ top left though!
proc sample*(self: PdBmp, x: uint32, y: uint32): Color =
  let pixelsPerByte = 8 div self.dibHeader.bitsPerPixel

  let rowIndex = if self.dibHeader.isTopDown:
    y
  else:
    uint32(self.dibHeader.imageHeight) - 1 - y

  let dataStart = rowIndex * self.dibHeader.rowSize + x div pixelsPerByte
  let dataSize = self.dibHeader.bitsPerPixel div 8 + 1

  let data = self.pixelData[dataStart..<dataStart + dataSize]

  case self.dibHeader.bitsPerPixel:
    of 4:
      let isHighNybble = x mod 2 == 0
      let paletteIndex = if isHighNybble: data[0] shr 4 else: data[0] and 0x0f

      return self.colorPalette[paletteIndex]
    of 8:
      return self.colorPalette[data[0]]
    else:
      raise ValueError.newException("TODO: Sample BPP other than 4, 8")
