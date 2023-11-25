import strutils
import math
import std/importutils

import playdate/api
import playdate/bindings/types

import ../../../src/pdbmp

import ditherPatterns

let bmps = @[
  PdBmp(filePath: "bmp/aseprite/indexed-4bpp-grayscale-24-24.bmp"),
  PdBmp(filePath: "bmp/aseprite/indexed-4bpp-200-120.bmp"),
  PdBmp(filePath: "bmp/aseprite/indexed-8bpp-400-240.bmp"),
  PdBmp(filePath: "bmp/aseprite/indexed-8bpp-gb-shop.bmp"),
  PdBmp(filePath: "bmp/aseprite/indexed-8bpp-gb-avatars.bmp"),
  PdBmp(filePath: "bmp/aseprite/indexed-8bpp-gb-outdoor.bmp"),
  PdBmp(filePath: "bmp/aseprite/indexed-8bpp-gb-overworld.bmp"),
  PdBmp(filePath: "bmp/aseprite/indexed-8bpp-gb-playground.bmp"),
  PdBmp(filePath: "bmp/aseprite/indexed-8bpp-gb-industrial.bmp"),
  PdBmp(filePath: "bmp/aseprite/indexed-8bpp-normal.bmp"),
  PdBmp(filePath: "bmp/aseprite/indexed-8bpp-sprout-lands.bmp"),
  PdBmp(filePath: "bmp/aseprite/rgb-32bpp-actor2rmmz.bmp"),

  PdBmp(filePath: "bmp/bmpsuite-2.7/g/pal1.bmp"),
  PdBmp(filePath: "bmp/bmpsuite-2.7/g/pal1bg.bmp"),
  PdBmp(filePath: "bmp/bmpsuite-2.7/g/pal1wb.bmp"),

  PdBmp(filePath: "bmp/bmpsuite-2.7/g/pal4.bmp"),
  PdBmp(filePath: "bmp/bmpsuite-2.7/g/pal4gs.bmp"),

  PdBmp(filePath: "bmp/bmpsuite-2.7/g/pal8-0.bmp"),
  PdBmp(filePath: "bmp/bmpsuite-2.7/g/pal8.bmp"),
  PdBmp(filePath: "bmp/bmpsuite-2.7/g/pal8gs.bmp"),
  PdBmp(filePath: "bmp/bmpsuite-2.7/g/pal8nonsquare.bmp"),
  PdBmp(filePath: "bmp/bmpsuite-2.7/g/pal8os2.bmp"),
  PdBmp(filePath: "bmp/bmpsuite-2.7/g/pal8topdown.bmp"),
  PdBmp(filePath: "bmp/bmpsuite-2.7/g/pal8w124.bmp"),
  PdBmp(filePath: "bmp/bmpsuite-2.7/g/pal8w125.bmp"),
  PdBmp(filePath: "bmp/bmpsuite-2.7/g/pal8w126.bmp"),

  PdBmp(filePath: "bmp/bmpsuite-2.7/g/rgb32.bmp"),
  PdBmp(filePath: "bmp/bmpsuite-2.7/g/rgb32bfdef.bmp"),
  PdBmp(filePath: "bmp/bmpsuite-2.7/g/rgb32bf.bmp"),
  PdBmp(filePath: "bmp/custom/rgb32bfdef2.bmp"),
]

var bmpIndex = 0
var bmpScale = 2
var isBButtonDown = false
var imgX = 0
var imgY = 0
var buttonState: tuple[current: PDButtons, pushed: PDButtons,
    released: PDButtons]
var ditherMode = 0

var font: LCDFont
var img: LCDBitmap
var infoImg: LCDBitmap

const scrollSpeed = 4
const ditherNames = @[
  "gb4Light",
  "gb4Dark",
  "gb5",
  "bayer8x8",
]

proc strokeOffsets(radius: int): seq[tuple[x: int, y: int]] =
  result = @[]
  for x in -radius..radius:
    for y in -radius..radius:
      if x*x + y*y <= radius*radius:
        result.add((x, y))

proc loadBmp(bmpIndex: int, bmpScale: int): void =
  try:
    let startAt = playdate.system.getElapsedTime()
    var bmp = bmps[bmpIndex]
    bmp.load()

    let bmpLoadAt = playdate.system.getElapsedTime()
    let bmpLoadDur = bmpLoadAt - startAt

    let bmpWidth = bmp.dibHeader.imageWidth
    let bmpHeight = bmp.dibHeader.imageHeight
    let bpp = bmp.dibHeader.bitsPerPixel

    img = playdate.graphics.newBitmap(
      bmpWidth * bmpScale, bmpHeight * bmpScale,
      LCDSolidColor.kColorClear
    )

    let imgInitAt = playdate.system.getElapsedTime()
    let imgInitDur = imgInitAt - bmpLoadAt

    playdate.graphics.pushContext(img)
    for x in 0..<bmpWidth:
      for y in 0..<bmpHeight:
        let sampledColor = bmp.sample(uint32(x), uint32(y))
        let luma = float(sampledColor.r) * 0.2126 + float(sampledColor.g) *
            0.7152 + float(sampledColor.b) * 0.0722

        # playdate.system.logToConsole("x,y;r,g,b,a: " & $(x) & "," & $(y) & ";" &
        #     $(sampledColor.r) & "," & $(sampledColor.g) & "," & $(
        #         sampledColor.b) & "," & $(sampledColor.a))

        playdate.graphics.fillRect(
          x * bmpScale, y * bmpScale, bmpScale, bmpScale,
          case ditherMode:
          of 0:
            gb4Light[int(luma) div 64]
          of 1:
            gb4Dark[int(luma) div 64]
          of 2:
            gb5[int(luma) div 51]
          else:
            bayer8x8[int(luma) div 4]
        )
    playdate.graphics.popContext()

    let imgDrawnAt = playdate.system.getElapsedTime()
    let imgDrawDur = imgDrawnAt - imgInitAt

    let sepInd = bmp.filePath.rfind("/")
    let fileName = bmp.filePath[sepInd+1..^1]
    let infoStrings = @[
      "w,h,bpp: " & $(bmpWidth) & "," & $(bmpHeight) & "," & $(bpp),
      "dither: " & $(ditherNames[ditherMode]),
      "bmpLoad: " & $((bmpLoadDur * 1000).formatFloat(ffDecimal, 2)) & "ms",
      "imgInit: " & $((imgInitDur * 1000).formatFloat(ffDecimal, 2)) & "ms",
      "imgDraw: " & $((imgDrawDur * 1000).formatFloat(ffDecimal, 2)) & "ms",
      fileName,
    ]

    let infoImgWidth = 400
    let fontHeight = font.getFontHeight().int
    let infoImgHeight = fontHeight * infoStrings.len + 4
    let newInfoImg = playdate.graphics.newBitmap(
      infoImgWidth,
      infoImgHeight,
      LCDSolidColor.kColorClear,
    )

    playdate.graphics.pushContext(newInfoImg)

    for i in 0..<infoStrings.len:
      let str = infoStrings[i]
      let strWidth = font.getTextWidth(
        str,
        str.len,
        PDStringEncoding.kUTF8Encoding,
        0
      )
      playdate.graphics.drawText(
        str,
        str.len.uint,
        PDStringEncoding.kUTF8Encoding,
        infoImgWidth - strWidth,
        i * fontHeight
      )

    playdate.graphics.popContext()

    infoImg = playdate.graphics.newBitmap(
      infoImgWidth,
      infoImgHeight,
      LCDSolidColor.kColorClear,
    )
    playdate.graphics.pushContext(infoImg)
    let offsets = strokeOffsets(2)
    playdate.graphics.setDrawMode(LCDBitmapDrawMode.kDrawModeFillWhite)
    for offset in offsets:
      newInfoImg.draw(offset.x, offset.y + 2,
          LCDBitmapFlip.kBitmapUnflipped)

    playdate.graphics.setDrawMode(LCDBitmapDrawMode.kDrawModeFillBlack)
    newInfoImg.draw(0, 2, LCDBitmapFlip.kBitmapUnflipped)
    playdate.graphics.popContext()
  except Exception as e:
    playdate.system.logToConsole("Error parsing BMP: " & e.msg)

proc handleInit(): void =
  playdate.display.setRefreshRate(50)

  font = try: playdate.graphics.newFont(
      "fonts/nico/nico-clean-16.pft") except: nil
  playdate.graphics.setFont(font)

  if font == nil:
    playdate.system.logToConsole("Error loading font")
    return

  loadBmp(bmpIndex, bmpScale)

proc update(): int {.raises: [].} =
  buttonState = playdate.system.getButtonsState()

  var needsLoad = false
  var needsPosReset = false
  let oldBmpIndex = bmpIndex

  if buttonState.pushed.contains(PDButton.kButtonB):
    isBButtonDown = true
  if buttonState.released.contains(PDButton.kButtonB):
    isBButtonDown = false

  # Scroll while B held
  if buttonState.current.contains(PDButton.kButtonUp):
    if isBButtonDown: imgY += scrollSpeed
  if buttonState.current.contains(PDButton.kButtonRight):
    if isBButtonDown: imgX -= scrollSpeed
  if buttonState.current.contains(PDButton.kButtonDown):
    if isBButtonDown: imgY -= scrollSpeed
  if buttonState.current.contains(PDButton.kButtonLeft):
    if isBButtonDown: imgX += scrollSpeed

  # Prev image
  if buttonState.pushed.contains(PDButton.kButtonLeft):
    if isBButtonDown: return
    bmpIndex -= 1
    if bmpIndex < 0:
      bmpIndex = bmps.len - 1
    needsLoad = true
    needsPosReset = true

  # Next image
  if buttonState.pushed.contains(PDButton.kButtonRight):
    if isBButtonDown: return
    bmpIndex += 1
    if bmpIndex >= bmps.len:
      bmpIndex = 0
    needsLoad = true
    needsPosReset = true

  # Increase scale
  if buttonState.pushed.contains(PDButton.kButtonUp):
    if isBButtonDown: return
    bmpScale += 1
    if bmpScale > 4:
      bmpScale = 4
    needsLoad = true
    needsPosReset = true

  # Decrease scale
  if buttonState.pushed.contains(PDButton.kButtonDown):
    if isBButtonDown: return
    bmpScale -= 1
    if bmpScale < 1:
      bmpScale = 1
    needsLoad = true
    needsPosReset = true

  # Change dither
  if buttonState.pushed.contains(PDButton.kButtonA):
    needsLoad = true
    ditherMode += 1
    if ditherMode >= ditherNames.len:
      ditherMode = 0

  # Change image if necessary
  if needsLoad:
    var oldBmp = bmps[oldBmpIndex]
    oldBmp.unload()

    loadBmp(bmpIndex, bmpScale)

    if needsPosReset:
      let bmp = bmps[bmpIndex]
      imgX = 200 - bmp.dibHeader.imageWidth * bmpScale div 2
      imgY = 120 - bmp.dibHeader.imageHeight * bmpScale div 2

  playdate.graphics.clear(LCDSolidColor.kColorWhite)
  if img != nil:
    img.draw(imgX, imgY, LCDBitmapFlip.kBitmapUnflipped)

  if infoImg != nil:
    infoImg.draw(
      400 - 5 - infoImg.width,
      240 - 5 - infoImg.height,
      LCDBitmapFlip.kBitmapUnflipped
    )

  # When crank is undocked, sample all pixels every frame
  if not playdate.system.isCrankDocked:
    let currentBmp = bmps[bmpIndex]
    let bmpWidth = currentBmp.dibHeader.imageWidth
    let bmpHeight = currentBmp.dibHeader.imageHeight

    let sampleStart = playdate.system.getElapsedTime()
    for y in 0..<bmpHeight:
      for x in 0..<bmpWidth:
        # Just discard the sample, don't actually do anything with it
        discard try: currentBmp.sample(x.uint32, y.uint32) except: (0, 0, 0, 0)

    let sampleDur = playdate.system.getElapsedTime() - sampleStart
    let sampleStr = "Sample: " & $((sampleDur * 1000).formatFloat(ffDecimal,
        2)) & "ms"
    let sampleStrWidth = font.getTextWidth(sampleStr, sampleStr.len,
        PDStringEncoding.kUTF8Encoding, 0)
    playdate.graphics.drawText(
      sampleStr,
      sampleStr.len.uint,
      PDStringEncoding.kUTF8Encoding,
      400 - 5 - sampleStrWidth,
      5.int,
    )

  playdate.system.drawFPS(0, 0)

  return 1

proc handler(event: PDSystemEvent, keycode: uint) {.raises: [].} =
  if event == kEventInit:
    handleInit()
    playdate.system.setUpdateCallback(update)

  # TODO:
  # if event == kEventInitLua:
  #   initPdBmpLua()

initSDK()
