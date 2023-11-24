import bitops
import system
import std/sugar

import playdate/api

import pdbmp/byteSeq
import pdbmp/Color
import pdbmp/ColorMask
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
  colorMask*: ColorMask
  pixelData: seq[byte]

# "BM"
const expectedMagicBytes = @[0x42'u8, 0x4d'u8]

const defaultColorMask = @[
  0x0000ff00'u32,
  0x00ff0000'u32,
  0xff000000'u32,
  0x000000ff'u32,
]

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

proc getShiftAmount(mask: uint32): int =
  var count = 0
  var m = mask
  while (m and 1) == 0 and m != 0:
    inc(count)
    m = m shr 1
  return count

proc parseColorMask(self: PdBmp) =
  self.colorMask = @[]
  self.colorMask.parse(
    self.file,
    self.filePath,
    self.dibHeader.paletteDataOffset,
    self.dibHeader.colorMaskCount
  )

proc parseColorPalette(self: PdBmp) =
  self.colorPalette = @[]
  self.colorPalette.parse(
    self.file,
    self.filePath,
    self.dibHeader.paletteDataOffset,
    self.dibHeader.usedColorsCount,
    self.dibHeader.paletteEntrySize,
  )

proc readPixelData(self: PdBmp) =
  self.file.seek(int(self.pixelDataOffset), SEEK_SET)

  if self.dibHeader.bitsPerPixel < 16:
    self.pixelData = collect(newSeq):
      for i in 0..<self.dibHeader.imageHeight:
        let rowData = self.file.read(self.dibHeader.rowSize).bytes
        rowData[0..<self.dibHeader.rowSizeUnpadded]
  elif self.dibHeader.bitsPerPixel == 32:
    let bitsPerPixel = self.dibHeader.bitsPerPixel
    let bytesPerPixel = int32(bitsPerPixel div 8)
    let totalPixels = self.dibHeader.imageHeight * self.dibHeader.imageWidth
    let allPixelDataSize = totalPixels * bytesPerPixel
    var allPixelData = newSeq[byte](allPixelDataSize)

    var dataIndex = 0
    for y in 0..<self.dibHeader.imageHeight:
      let rowData = self.file.read(self.dibHeader.rowSize).bytes

      for x in 0..<self.dibHeader.imageWidth:
        let pixelOffset = x * bytesPerPixel
        let originalPixelInt = cast[ptr uint32](unsafeAddr rowData[
            pixelOffset])[]

        let red = (originalPixelInt and self.colorMask[
            0]) shr bitops.countTrailingZeroBits(self.colorMask[0])
        let green = (originalPixelInt and self.colorMask[
            1]) shr bitops.countTrailingZeroBits(self.colorMask[1])
        let blue = (originalPixelInt and self.colorMask[
            2]) shr bitops.countTrailingZeroBits(self.colorMask[2])

        allPixelData[dataIndex] = byte(red)
        allPixelData[dataIndex + 1] = byte(green)
        allPixelData[dataIndex + 2] = byte(blue)

        if self.colorMask.len > 3:
          let alpha = (originalPixelInt and self.colorMask[
              3]) shr bitops.countTrailingZeroBits(self.colorMask[3])
          allPixelData[dataIndex + 3] = byte(alpha)
          dataIndex += 4
        else:
          dataIndex += 3

    self.pixelData = allPixelData

proc load*(self: var PdBmp) =
  self.openFile()

  self.parseFileHeader()

  self.parseDibHeader()

  if self.dibHeader.hasPalette:
    self.parseColorPalette()
  elif self.dibHeader.compressionType == DibCompressionType.BiBitfields:
    self.parseColorMask()
  else:
    self.colorMask = defaultColorMask

  self.readPixelData()

  self.file.close()
  self.file = nil

proc unload*(self: var PdBmp) =
  self.pixelData = @[]

proc sampleIndex*(self: PdBmp, x: uint32, y: uint32): byte =
  # TODO:
  discard

# TODO: Raise if x, y out of range
proc sample*(self: PdBmp, x: uint32, y: uint32): Color =
  let bitsPerPixel = self.dibHeader.bitsPerPixel
  let bytesPerPixel = bitsPerPixel div 8

  let rowIndex = if self.dibHeader.isTopDown:
    y
  else:
    uint32(self.dibHeader.imageHeight) - 1 - y

  var dataStart: uint32

  case bitsPerPixel:
    of 1, 4:
      let pixelsPerByte = 8 div bitsPerPixel
      let bytePosition = x div pixelsPerByte
      dataStart = rowIndex * self.dibHeader.rowSizeUnpadded + bytePosition
    else:
      dataStart = rowIndex * self.dibHeader.rowSizeUnpadded + x * bytesPerPixel

  case bitsPerPixel:
    of 1:
      let bitIndex = 7 - byte(x mod 8)
      let paletteIndex = (self.pixelData[dataStart] and (
          1'u8 shl bitIndex)) shr bitIndex

      return self.colorPalette[paletteIndex]
    of 4:
      let isHighNybble = x mod 2 == 0
      let paletteIndex = if isHighNybble: self.pixelData[
          dataStart] shr 4 else: self.pixelData[dataStart] and 0x0f

      return self.colorPalette[paletteIndex]
    of 8:
      return self.colorPalette[self.pixelData[dataStart]]
    of 32:
      let pixelPtr = cast[ptr uint32](addr self.pixelData[dataStart])
      let pixel = pixelPtr[]

      let
        r = uint8((pixel) and 0xFF)
        g = uint8((pixel shr 8) and 0xFF)
        b = uint8((pixel shr 16) and 0xFF)
        a = uint8((pixel shr 24) and 0xFF)
      return (r, g, b, a)
    else:
      raise ValueError.newException("Unsupported bpp value " & $(bitsPerPixel))
