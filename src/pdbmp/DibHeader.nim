import std/math
import tables

import playdate/api

import byteSeq
import util

type DibHeaderType* = enum
  Unknown = 0'u32,
  BitmapInfoHeader,
  BitmapV3InfoHeader

type DibCompressionType* = enum
  BiRgb = 0'u32,    # Uncompressed
  BiRle8,           # 8 bpp RLE encoding
  BiRle4,           # 4 bpp RLE encoding
  BiBitfields,      # Uncompressed 16/32 bpp
  BiJpeg,           # JPEG image data
  BiPng,            # PNG image data
  BiAlphaBitfields, # RGBA bitfield masks

const DibHeaderSizeVersionMap = {
  40'u32: BitmapInfoHeader,
  56: BitmapV3InfoHeader,
}.toTable

type DibHeader* = object
  headerSize*: uint32
  headerType*: DibHeaderType
  imageWidth*: int32
  imageHeight*: int32
  bitsPerPixel*: uint16
  compressionType*: DibCompressionType
  imageDataSize*: uint32
  usedColorsCount*: uint32
  hasPalette*: bool
  paletteDataOffset*: int

# https://learn.microsoft.com/en-us/previous-versions/dd183376(v=vs.85)
proc parseBitmapInfoHeader(self: var DibHeader, file: SDFile) =
  log("parseBitmapInfoHeader")
  # Read width, height
  self.imageWidth = file.read(4).bytes.toInt32()
  # "If `biHeight` is positive, the bitmap is a bottom-up DIB and its origin is the lower-left corner. If biHeight is negative, the bitmap is a top-down DIB and its origin is the upper-left corner"
  self.imageHeight = file.read(4).bytes.toInt32()

  # Skip color planes
  file.seek(2, SEEK_CUR)

  # Read bits per pixel, compression, image data size
  self.bitsPerPixel = file.read(2).bytes.toUint16()
  self.compressionType = cast[DibCompressionType](file.read(4).bytes.toUint32())
  self.imageDataSize = file.read(4).bytes.toUint32()

  # Skip pixels per meter (x, y)
  file.seek(8, SEEK_CUR)

  # Determine number of used colors
  let storedUsedColorsCount = file.read(4).bytes.toUint32()
  if storedUsedColorsCount == 0:
    # "If this value is zero, the bitmap uses the maximum number of colors corresponding to the value of the biBitCount member for the compression mode specified by biCompression."
    self.usedColorsCount = 2'u32 ^ self.bitsPerPixel
  else:
    self.usedColorsCount = storedUsedColorsCount

  # Determine whether this image uses a palette, and where that palette starts
  case self.bitsPerPixel:
    of 1, 4, 8:
      self.hasPalette = true
      # Static palette start (right after fixed length header)
      self.paletteDataOffset = 54
    else:
      self.hasPalette = false

  # Skip "important" colors
  file.seek(4, SEEK_CUR)

proc parseBitmapV3InfoHeader(self: var DibHeader, file: SDFile) =
  log("parseBitmapV3InfoHeader")

proc parse*(self: var DibHeader, file: SDFile, filePath: string) =
  # Go to start of DIB header
  file.seek(14, SEEK_SET)

  # Read header size to determine type
  self.headerSize = file.read(4).bytes.toUint32()
  self.headerType = DibHeaderSizeVersionMap.getOrDefault(self.headerSize)

  # Continue parsing based on detected header type. At offset 18
  case self.headerType:
    of BitmapInfoHeader:
      self.parseBitmapInfoHeader(file)
    of BitmapV3InfoHeader:
      self.parseBitmapV3InfoHeader(file)
    of Unknown:
      raise IOError.newException("Unsupported BMP header size " & $(
          self.headerSize) & " for file " & filePath)
